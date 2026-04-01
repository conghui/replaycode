# Claude Code v2.1.88 — Open Source Build from Decompiled Source

> Successfully rebuilt the Claude Code CLI from decompiled TypeScript source.
> Full API interaction, tool execution, and headless mode working end-to-end.

## What Is This?

This project takes the **decompiled source code** of Anthropic's [Claude Code](https://claude.ai/code) CLI (extracted from the npm package `@anthropic-ai/claude-code` v2.1.88) and produces a **fully functional, buildable CLI** using Node.js and esbuild.

The original package ships as a single bundled `cli.js` (~12MB) compiled with Bun. This project reconstructs the build pipeline using standard Node.js tooling, making the source code **readable, buildable, and runnable**.

## Build

```bash
# Prerequisites: Node.js >= 18
npm install
node scripts/build.mjs

# Output: dist/cli.cjs (26.5MB)
```

Build completes in ~15 seconds, producing a single CJS bundle.

## Quick Start

```bash
export ANTHROPIC_API_KEY=sk-ant-...

# Version check
node dist/cli.cjs --version
# → 2.1.88 (Claude Code)

# Single prompt (headless mode)
node dist/cli.cjs -p "Hello, Claude!"

# With tool access
node dist/cli.cjs -p "List all .ts files in src/" --dangerously-skip-permissions

# JSON output with metrics
node dist/cli.cjs -p "What is 2+2?" --output-format json

# Custom system prompt
node dist/cli.cjs -p "What are you?" --system-prompt "You are a pirate."
```

## Verified Features

| Category | Feature | Status |
|----------|---------|--------|
| **CLI** | `--version`, `--help` | Working |
| **CLI** | `-p` / `--print` (headless mode) | Working |
| **CLI** | `--output-format json` | Working |
| **CLI** | `--system-prompt` | Working |
| **CLI** | `--dangerously-skip-permissions` | Working |
| **Tools** | Bash (shell command execution) | Working |
| **Tools** | FileRead (read file contents) | Working |
| **Tools** | FileWrite (create/write files) | Working |
| **Tools** | FileEdit (edit existing files) | Working |
| **Tools** | Grep (search file contents) | Working |
| **Tools** | Glob (find files by pattern) | Working |
| **Tools** | WebFetch (HTTP requests) | Working |
| **API** | Streaming responses | Working |
| **API** | Tool use / function calling | Working |
| **API** | Multi-turn conversations | Working |
| **API** | Cost tracking & token usage | Working |

### Not Yet Available

- Interactive REPL mode (requires Ink/React terminal UI)
- MCP server connections
- Syntax-highlighted diff display (native `color-diff-napi` stubbed)
- Image processing (`sharp` stubbed)
- OAuth login flow

## Showcase: Building a Project from Scratch

The following demo shows the MVP building a complete weather CLI tool autonomously — creating files, writing code, fetching live data, and running tests:

```bash
$ mkdir /tmp/weather-demo && cd /tmp/weather-demo

$ node dist/cli.cjs -p "
  Build a Node.js CLI weather tool:
  1. Create package.json (name: weather-cli, type: module)
  2. Create src/weather.mjs: takes city as argv,
     fetches https://wttr.in/{city}?format=j1,
     prints formatted weather (temp, humidity, wind, description)
  3. Run it with: node src/weather.mjs Beijing
" --dangerously-skip-permissions
```

**Result** — Claude Code autonomously:

1. **Inspected** the empty directory (Bash: `ls -la`)
2. **Created** `package.json` (FileWrite)
3. **Created** `src/weather.mjs` with full error handling (FileWrite)
4. **Executed** `node src/weather.mjs Beijing` and confirmed output (Bash)
5. **Reported** the result: "Beijing is 16°C and sunny"

Generated code:

```javascript
// src/weather.mjs
const city = process.argv[2];
if (!city) {
  console.error("Usage: node src/weather.mjs <city>");
  process.exit(1);
}

const res = await fetch(`https://wttr.in/${encodeURIComponent(city)}?format=j1`);
const data = await res.json();
const current = data.current_condition[0];

console.log(`\n  Weather for ${city}`);
console.log(`  ${"─".repeat(30)}`);
console.log(`  Temperature : ${current.temp_C}°C`);
console.log(`  Humidity    : ${current.humidity}%`);
console.log(`  Wind        : ${current.windspeedKmph} km/h ${current.winddir16Point}`);
console.log(`  Description : ${current.weatherDesc[0].value}\n`);
```

Running independently:

```
$ node src/weather.mjs Shanghai

  Weather for Shanghai
  ──────────────────────────────
  Temperature : 19°C
  Humidity    : 52%
  Wind        : 5 km/h W
  Description : Sunny

$ node src/weather.mjs Tokyo

  Weather for Tokyo
  ──────────────────────────────
  Temperature : 17°C
  Humidity    : 88%
  Wind        : 18 km/h NW
  Description : Light rain
```

## How the Build Works

The build solves several challenges in reconstructing a working CLI from decompiled source:

| Challenge | Solution |
|-----------|----------|
| **108 missing feature-gated modules** | Smart stub generation: parse esbuild errors, resolve import paths, scan source for expected exports, generate type-correct stubs |
| **`feature()` from `bun:bundle`** | Remove all `import { feature }` statements, provide `feature()` → `false` via `--banner:js` |
| **ESM/CJS interop** | Bundle ALL npm packages into one CJS file (no external requires) |
| **`import.meta.url` in CJS** | Build-time transform: `fileURLToPath(import.meta.url)` → `__filename` |
| **Internal Anthropic packages** | Create local stubs with correct exports (`@ant/claude-for-chrome-mcp`) |
| **Native NAPI modules** | Pure JS stub replacements (`color-diff-napi`, `sharp`) |
| **MACRO compile-time constants** | String replacement: `MACRO.VERSION` → `'2.1.88'` |

## Technical Details

- **Source**: 1,884 TypeScript files, ~512K lines of code
- **Output**: Single `dist/cli.cjs` file, 26.5MB
- **Build tool**: esbuild (bundler), no Bun required
- **Runtime**: Node.js >= 18
- **Build time**: ~15 seconds
- **API**: Uses `@anthropic-ai/sdk` for Claude API calls

## Disclaimer

All source code is the intellectual property of **Anthropic**. This repository is provided strictly for technical research, study, and educational exchange. **Commercial use is strictly prohibited.**

## License

Research and educational use only. See [README.md](README.md) for full disclaimer.
