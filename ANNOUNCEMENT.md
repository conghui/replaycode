# We Rebuilt Claude Code from Decompiled Source — And It Actually Works

## TL;DR

We took the decompiled TypeScript source of Anthropic's Claude Code CLI (v2.1.88), reconstructed the build pipeline using standard Node.js tooling, and produced a **fully functional CLI** — complete with API calls, tool execution, and multi-turn conversations. No Bun required.

```bash
$ node dist/cli.cjs --version
2.1.88 (Claude Code)

$ node dist/cli.cjs -p "What is 2+2?"
4
```

**9/9 automated tests passing.** Bash, file operations, grep, web fetch — all working.

---

## Why This Matters

Claude Code is Anthropic's flagship agentic coding tool — but it ships as a single 12MB bundled JavaScript file compiled with Bun. No readable source code. No way to understand how it works under the hood.

We changed that.

Starting from the npm package `@anthropic-ai/claude-code`, we:

1. **Extracted** 1,884 TypeScript source files (~512K lines of code)
2. **Analyzed** the architecture: entry points, query engine, tool system, 40+ tools, permission model
3. **Rebuilt** the entire thing with esbuild — solving ESM/CJS interop, 108 missing internal modules, compile-time feature gates, and native binary stubs
4. **Verified** it produces identical output to the official binary

## What Works

| Feature | Status |
|---------|--------|
| `--version`, `--help` | ✅ |
| `-p` headless mode | ✅ |
| Bash tool (run shell commands) | ✅ |
| FileRead / FileWrite / FileEdit | ✅ |
| Grep / Glob (code search) | ✅ |
| WebFetch (HTTP requests) | ✅ |
| JSON output (`--output-format json`) | ✅ |
| Custom system prompts | ✅ |
| Multi-turn tool use | ✅ |
| Streaming responses | ✅ |
| Cost tracking | ✅ |

## Live Demo

We asked our rebuilt CLI to create a complete weather tool from scratch:

```bash
$ node dist/cli.cjs -p "
  Build a Node.js weather CLI:
  create package.json, write src/weather.mjs that fetches wttr.in,
  then run it for Beijing
" --dangerously-skip-permissions
```

Claude Code autonomously:
- Created `package.json` ✅
- Wrote `src/weather.mjs` with error handling ✅
- Ran `node src/weather.mjs Beijing` ✅
- Reported: "Beijing is 16°C and sunny" ✅

The generated code runs independently:

```
$ node src/weather.mjs Tokyo

  Weather for Tokyo
  ──────────────────────────────
  Temperature : 17°C
  Humidity    : 88%
  Wind        : 18 km/h NW
  Description : Light rain
```

## Build It Yourself

```bash
git clone https://github.com/conghui/claude-code-source-code.git
cd claude-code-source-code
npm install
node scripts/build.mjs    # → dist/cli.cjs (26.5MB, ~15 seconds)

# Verify
bash scripts/verify.sh    # → 9/9 tests passing
```

## The Hard Parts

Rebuilding wasn't straightforward. Here's what we had to solve:

| Problem | Solution |
|---------|----------|
| Bun's `feature()` compile-time gates | `--banner:js` injects `feature()→false` globally |
| 108 missing internal Anthropic modules | Smart stub generator: parse esbuild errors → resolve paths → scan imports → generate typed stubs |
| ESM packages in CJS bundle | Bundle everything (no external requires) |
| `import.meta.url` undefined in CJS | Build-time transform → `__filename` |
| Native NAPI modules (`color-diff-napi`, `sharp`) | Pure JS stub replacements |
| Internal packages (`@ant/claude-for-chrome-mcp`) | Local stubs with correct exports |

## What's Next

This is the MVP — headless mode with core tools. Still to come:
- Interactive REPL mode (Ink/React terminal UI)
- MCP server connections
- Full plugin/skill system

## Star & Contribute

If you find this useful for understanding how agentic coding tools work under the hood:

⭐ **Star the repo**: [github.com/conghui/claude-code-source-code](https://github.com/conghui/claude-code-source-code)

PRs welcome — especially for:
- Getting interactive mode working
- MCP support
- Additional tool verification

---

*Disclaimer: All source code is the intellectual property of Anthropic. This project is for research and educational purposes only. Commercial use is prohibited.*
