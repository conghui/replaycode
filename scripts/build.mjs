#!/usr/bin/env node
/**
 * build.mjs — Build Claude Code v2.1.88 from decompiled source
 *
 * Strategy:
 *   1. Copy src/ + stubs/ → build-src/
 *   2. Transform: feature() → false, MACRO → literals, remove bun-bundle imports
 *   3. Create entry wrapper + build tsconfig
 *   4. Iteratively bundle with esbuild, creating stubs for missing modules
 */

import { readdir, readFile, writeFile, mkdir, cp, rm, stat } from 'node:fs/promises'
import { join, dirname, resolve } from 'node:path'
import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = join(__dirname, '..')
const VERSION = '2.1.88'

// ── Feature Flags ─────────────────────────────────────────────────────────────
// Safe flags: these only unlock existing code in the bundle (no missing modules)
const SAFE_FLAGS = [
  'BASH_CLASSIFIER',        // Auto-classifies bash commands for safe/unsafe execution
  'TRANSCRIPT_CLASSIFIER',  // Auto-mode (auto-classifier for tool permissions)
  'SHOT_STATS',             // Tracks shot distribution metrics
  'TOKEN_BUDGET',           // Token budget tracking for compaction
  'PROMPT_CACHE_BREAK_DETECTION', // Detects prompt cache invalidation
  'BUILTIN_EXPLORE_PLAN_AGENTS',  // Enables Explore & Plan agent definitions
  'MESSAGE_ACTIONS',        // Message action keybindings & handlers
  'QUICK_SEARCH',           // Quick search UI overlay
]

// Parse ENABLE_FLAGS from environment: comma-separated list of additional flags to enable
// Example: ENABLE_FLAGS=COORDINATOR_MODE,FORK_SUBAGENT npm run build
const extraFlags = (process.env.ENABLE_FLAGS || '').split(',').map(f => f.trim()).filter(Boolean)
const ENABLED_FLAGS = new Set([...SAFE_FLAGS, ...extraFlags])

if (extraFlags.length > 0) {
  console.log(`⚡ Extra flags enabled: ${extraFlags.join(', ')}`)
}
console.log(`⚡ Total enabled flags: ${[...ENABLED_FLAGS].join(', ')}`)
const BUILD = join(ROOT, 'build-src')
const ENTRY = join(BUILD, 'entry.ts')
const OUT_DIR = join(ROOT, 'dist')
const OUT_FILE = join(OUT_DIR, 'cli.cjs')
const ESBUILD = join(ROOT, 'node_modules', '.bin', 'esbuild')

// ── Helpers ────────────────────────────────────────────────────────────────

async function* walk(dir) {
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const p = join(dir, e.name)
    if (e.isDirectory() && e.name !== 'node_modules') yield* walk(p)
    else yield p
  }
}

async function exists(p) { try { await stat(p); return true } catch { return false } }

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 1: Copy source AND stubs
// ══════════════════════════════════════════════════════════════════════════════

console.log('🔧 Phase 1: Copying source...')
await rm(BUILD, { recursive: true, force: true })
await mkdir(BUILD, { recursive: true })
await cp(join(ROOT, 'src'), join(BUILD, 'src'), { recursive: true })
await cp(join(ROOT, 'stubs'), join(BUILD, 'stubs'), { recursive: true })
console.log('✅ Phase 1: Copied src/ and stubs/ → build-src/')

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 2: Transform source
// ══════════════════════════════════════════════════════════════════════════════

console.log('🔧 Phase 2: Transforming source...')
let transformCount = 0

const MACROS = {
  'MACRO.VERSION': `'${VERSION}'`,
  'MACRO.BUILD_TIME': `'${new Date().toISOString()}'`,
  'MACRO.FEEDBACK_CHANNEL': `'https://github.com/anthropics/claude-code/issues'`,
  'MACRO.ISSUES_EXPLAINER': `'https://github.com/anthropics/claude-code/issues/new/choose'`,
  'MACRO.FEEDBACK_CHANNEL_URL': `'https://github.com/anthropics/claude-code/issues'`,
  'MACRO.ISSUES_EXPLAINER_URL': `'https://github.com/anthropics/claude-code/issues/new/choose'`,
  'MACRO.NATIVE_PACKAGE_URL': `'@anthropic-ai/claude-code'`,
  'MACRO.PACKAGE_URL': `'@anthropic-ai/claude-code'`,
  'MACRO.VERSION_CHANGELOG': `''`,
}

for await (const file of walk(join(BUILD, 'src'))) {
  if (!file.match(/\.[tj]sx?$/)) continue

  let src = await readFile(file, 'utf8')
  let changed = false

  // 2a. feature('FLAG') → true (if enabled) or false (if disabled)
  const featureRe = /\bfeature\s*\(\s*['"]([A-Z_]+)['"]\s*\)/g
  if (featureRe.test(src)) {
    src = src.replace(/\bfeature\s*\(\s*['"]([A-Z_]+)['"]\s*\)/g, (match, flag) => {
      return ENABLED_FLAGS.has(flag) ? 'true' : 'false'
    })
    changed = true
  }

  // 2b. MACRO.X → literals
  for (const [k, v] of Object.entries(MACROS)) {
    if (src.includes(k)) {
      src = src.replaceAll(k, v)
      changed = true
    }
  }

  // 2c. REMOVE all feature imports (bun:bundle and stubs/bun-bundle)
  // feature() will be provided globally via --banner:js
  const before = src
  src = src.replace(/import\s*\{\s*feature\s*\}\s*from\s*['"][^'"]*['"];?\s*\n?/g, (match) => {
    // Only remove if it's a feature import from bun:bundle or stubs/bun-bundle
    if (match.includes('bun:bundle') || match.includes('bun-bundle')) {
      return '// feature() provided globally\n'
    }
    return match
  })
  if (src !== before) changed = true

  // 2d. Replace import.meta.url with CJS equivalent
  const before3 = src
  src = src.replace(
    /fileURLToPath\s*\(\s*import\.meta\.url\s*\)/g,
    '__filename'
  )
  if (src !== before3) changed = true

  // 2e. Remove global.d.ts imports
  const before2 = src
  src = src.replace(/import\s*['"][^'"]*global\.d\.ts['"];?\s*\n?/g, '')
  if (src !== before2) changed = true

  if (changed) {
    await writeFile(file, src, 'utf8')
    transformCount++
  }
}
console.log(`✅ Phase 2: Transformed ${transformCount} files`)

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 3: Create entry wrapper + tsconfig
// ══════════════════════════════════════════════════════════════════════════════

await writeFile(ENTRY, `// Claude Code v${VERSION} — built from source
import './src/entrypoints/cli.tsx'
`, 'utf8')

await writeFile(join(BUILD, 'tsconfig.json'), JSON.stringify({
  compilerOptions: {
    target: "ES2022",
    module: "ESNext",
    moduleResolution: "bundler",
    esModuleInterop: true,
    allowSyntheticDefaultImports: true,
    strict: false,
    skipLibCheck: true,
    resolveJsonModule: true,
    jsx: "react-jsx",
    baseUrl: ".",
    paths: { "bun:bundle": ["stubs/bun-bundle.ts"] },
    types: ["node"],
    lib: ["ES2022", "DOM"],
    noEmit: true,
  },
  include: ["src/**/*", "stubs/**/*"],
  exclude: ["node_modules"],
}, null, 2), 'utf8')

// Create a feature() shim that esbuild will inject into every module
const enabledFlagsJSON = JSON.stringify([...ENABLED_FLAGS])
await writeFile(join(BUILD, 'feature-shim.js'), `
// Shim for bun:bundle feature() — checks against enabled flags
const _enabled = new Set(${enabledFlagsJSON});
export function feature(_flag) { return _enabled.has(_flag); }
`, 'utf8')

console.log('✅ Phase 3: Created entry wrapper and build tsconfig')

// ══════════════════════════════════════════════════════════════════════════════
// PHASE 4: Stub internal packages + iterative bundle
// ══════════════════════════════════════════════════════════════════════════════

// Create stubs for internal/unavailable packages
// Create stubs for internal/native packages with proper exports
const internalStubs = {
  '@ant/claude-for-chrome-mcp': `
export const BROWSER_TOOLS = []
export function createClaudeForChromeMcpServer() { return {} }
export default {}
`,
  'color-diff-napi': `
export class ColorDiff { static fromRaw() { return new ColorDiff() }; render() { return '' } }
export class ColorFile { static fromRaw() { return new ColorFile() }; render() { return '' } }
export function getSyntaxTheme() { return {} }
export default {}
`,
  'modifiers-napi': `
export default {}
`,
  'sharp': `
export default function sharp() { return { metadata: async () => ({}), resize: () => sharp(), toBuffer: async () => Buffer.from('') } }
`,
}
for (const [pkg, code] of Object.entries(internalStubs)) {
  const pkgDir = join(ROOT, 'node_modules', pkg)
  await mkdir(pkgDir, { recursive: true }).catch(() => {})
  await writeFile(join(pkgDir, 'package.json'), JSON.stringify({
    name: pkg, version: '0.0.0', type: 'module', main: 'index.js'
  }), 'utf8')
  await writeFile(join(pkgDir, 'index.js'), code, 'utf8')
  console.log(`   Created stub: ${pkg}`)
}

await mkdir(OUT_DIR, { recursive: true })

// Packages that must be external (only truly unavailable ones)
const EXTERNAL_PKGS = [
  'bun:*',
]
const externalFlags = EXTERNAL_PKGS.map(p => `--external:${p}`).join(' ')

const MAX_ROUNDS = 15
let succeeded = false

for (let round = 1; round <= MAX_ROUNDS; round++) {
  console.log(`\n🔨 Phase 4 round ${round}/${MAX_ROUNDS}: Bundling...`)

  let esbuildOutput = ''
  try {
    execSync([
      `"${ESBUILD}"`,
      `"${ENTRY}"`,
      '--bundle',
      '--platform=node',
      '--target=node18',
      '--format=cjs',
      `--outfile="${OUT_FILE}"`,
      externalFlags,
      `--banner:js="var _enabledFlags=new Set(${enabledFlagsJSON.replace(/"/g, '\\"')});function feature(_f){return _enabledFlags.has(_f);}"`,
      '--allow-overwrite',
      '--log-level=error',
      '--log-limit=0',
      '--sourcemap',
      `--tsconfig="${join(BUILD, 'tsconfig.json')}"`,
      '--loader:.md=text',
      '--loader:.txt=text',
    ].join(' '), {
      cwd: BUILD,
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: true,
    })
    succeeded = true
    break
  } catch (e) {
    esbuildOutput = (e.stderr?.toString() || '') + (e.stdout?.toString() || '')
  }

  // Parse errors
  const blocks = esbuildOutput.split('✘ [ERROR]')
  const resolvedPaths = new Map()
  let totalMissing = 0
  const exportErrors = []
  const syntaxErrors = []

  for (const block of blocks) {
    // "Could not resolve" errors
    const modMatch = block.match(/Could not resolve "([^"]+)"/)
    if (modMatch) {
      const mod = modMatch[1]
      if (mod.startsWith('node:') || mod.startsWith('bun:')) continue
      totalMissing++

      const srcMatch = block.match(/^\s+(src\/[^\s:]+):\d+:\d+:/m)
      if (!srcMatch) continue
      const sourceDir = join(BUILD, dirname(srcMatch[1]))
      const resolved = resolve(sourceDir, mod)

      if (!resolvedPaths.has(resolved)) resolvedPaths.set(resolved, new Set())
      const importLine = block.match(/import\s*\{([^}]+)\}\s*from/)
      if (importLine) {
        for (const name of importLine[1].split(',').map(s => s.trim().split(/\s+as\s+/)[0])) {
          resolvedPaths.get(resolved).add(name)
        }
      }
      continue
    }

    // "No matching export" errors
    const exportMatch = block.match(/No matching export in "([^"]+)" for import "([^"]+)"/)
    if (exportMatch) {
      exportErrors.push({ file: join(BUILD, exportMatch[1]), name: exportMatch[2] })
      continue
    }

    // Syntax errors (from bad stubs)
    const syntaxMatch = block.match(/Expected .+ but found/)
    if (syntaxMatch) {
      syntaxErrors.push(block.slice(0, 200))
    }
  }

  // Fix export errors
  let exportFixCount = 0
  for (const { file, name } of exportErrors) {
    if (await exists(file)) {
      let content = await readFile(file, 'utf8')
      if (!content.includes(`export const ${name}`) && !content.includes(`export class ${name}`) && !content.includes(`export type ${name}`)) {
        if (/^[A-Z]/.test(name)) {
          content += `\nexport class ${name} {}\n`
        } else {
          content += `\nexport const ${name} = undefined\n`
        }
        await writeFile(file, content, 'utf8')
        exportFixCount++
      }
    }
  }

  if (totalMissing === 0 && exportErrors.length === 0) {
    const errLines = esbuildOutput.split('\n').filter(l => l.includes('ERROR')).slice(0, 15)
    console.log('❌ Remaining errors:')
    errLines.forEach(l => console.log('   ' + l))
    break
  }

  console.log(`   Missing: ${totalMissing} modules (${resolvedPaths.size} unique), ${exportErrors.length} export errors`)

  // Create stubs for missing modules
  let stubCount = 0
  for (const [resolved, importNames] of resolvedPaths) {
    // Check if already exists
    let alreadyExists = false
    for (const ext of ['', '.ts', '.tsx', '.js', '.jsx', '/index.ts', '/index.tsx', '/index.js']) {
      if (await exists(resolved + ext)) { alreadyExists = true; break }
    }
    if (alreadyExists) continue

    let targetPath = resolved
    if (!/\.[a-z]+$/.test(targetPath)) targetPath += '.ts'
    if (targetPath.endsWith('.js')) targetPath = targetPath.replace(/\.js$/, '.ts')

    await mkdir(dirname(targetPath), { recursive: true }).catch(() => {})

    if (/\.(txt|md)$/.test(targetPath)) {
      await writeFile(targetPath, '', 'utf8')
      stubCount++
      continue
    }
    if (targetPath.endsWith('.json')) {
      await writeFile(targetPath, '{}', 'utf8')
      stubCount++
      continue
    }

    // Scan source to find ALL expected exports from this module
    const valueNames = new Set(importNames)
    const typeNames = new Set()
    const modBasename = resolved.split('/').pop().replace(/\.[tj]sx?$/, '')

    try {
      const searchOutput = execSync(
        `grep -rh "from.*${modBasename}" "${join(BUILD, 'src')}" 2>/dev/null || true`,
        { encoding: 'utf8', timeout: 5000 }
      )
      for (const line of searchOutput.split('\n')) {
        // import type { X } from '...'
        const typeImport = line.match(/import\s+type\s*\{([^}]+)\}\s*from/)
        if (typeImport) {
          for (const n of typeImport[1].split(',').map(s => s.trim().split(/\s+as\s+/)[0])) {
            if (n && /^[a-zA-Z_$]/.test(n)) typeNames.add(n)
          }
          continue
        }
        // import { type X, Y } from '...'
        const mixedImport = line.match(/import\s*\{([^}]+)\}\s*from/)
        if (mixedImport) {
          for (let n of mixedImport[1].split(',').map(s => s.trim())) {
            n = n.split(/\s+as\s+/)[0]
            if (n.startsWith('type ')) {
              const tn = n.replace(/^type\s+/, '')
              if (tn && /^[a-zA-Z_$]/.test(tn)) typeNames.add(tn)
            } else if (n && /^[a-zA-Z_$]/.test(n)) {
              valueNames.add(n)
            }
          }
          continue
        }
        // import X from '...'
        const defM = line.match(/import\s+(\w+)\s+from/)
        if (defM && defM[1] !== 'type') valueNames.add(defM[1])
      }
    } catch {}

    let stub = `// Auto-generated stub for missing module\n`
    for (const name of typeNames) {
      stub += `export type ${name} = any\n`
    }
    for (const name of valueNames) {
      if (name === 'default') continue
      const clean = name.replace(/^type\s+/, '')
      if (!clean || typeNames.has(clean)) continue
      stub += /^[A-Z]/.test(clean) ? `export class ${clean} {}\n` : `export const ${clean} = undefined\n`
    }
    stub += `export default {}\n`
    await writeFile(targetPath, stub, 'utf8')
    stubCount++
  }

  console.log(`   Created ${stubCount} stubs, fixed ${exportFixCount} exports`)

  if (stubCount === 0 && exportFixCount === 0) {
    console.log('   ⚠️  No progress. Dumping errors:')
    const lines = esbuildOutput.split('\n').filter(l => l.includes('ERROR')).slice(0, 15)
    lines.forEach(l => console.log('   ' + l))
    break
  }
}

if (succeeded) {
  const size = (await stat(OUT_FILE)).size
  console.log(`\n✅ Build succeeded: ${OUT_FILE}`)
  console.log(`   Size: ${(size / 1024 / 1024).toFixed(1)}MB`)
  console.log(`\n   Test:  node ${OUT_FILE} --version`)
  console.log(`          node ${OUT_FILE} -p "Hello"`)
} else {
  console.error('\n❌ Build failed after all rounds.')
  process.exit(1)
}
