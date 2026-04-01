# ReplayCode: We Rebuilt Claude Code from Decompiled Source — And It Actually Works

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
git clone https://github.com/conghui/replaycode.git
cd replaycode
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

## Where We Are — and Where We're Going

**ReplayCode is currently equivalent to Claude Code v2.1.88** — the version released in late May 2025. At that point, Claude Code already had:

- 40+ built-in tools (Bash, FileRead/Write/Edit, Grep, Glob, WebFetch, Agent, etc.)
- Multi-turn agentic loop with streaming
- Full permission model and cost tracking
- Headless mode with JSON output

Meanwhile, **the official Claude Code has continued evolving rapidly** — newer versions have added interactive REPL improvements, MCP server support, enhanced multi-agent coordination, voice mode, and more.

**The gap between v2.1.88 and the latest Claude Code is our opportunity.** Every missing feature is a chance for the community to understand, implement, and innovate.

## Roadmap: Closing the Gap

| Priority | Feature | Status |
|----------|---------|--------|
| P0 | Interactive REPL mode (Ink/React terminal UI) | Not started |
| P0 | MCP server connections | Not started |
| P1 | Full plugin/skill system | Not started |
| P1 | Multi-agent coordinator mode | Stubbed |
| P2 | Voice mode (push-to-talk) | Stubbed |
| P2 | KAIROS autonomous agent mode | Stubbed |

## Join Us — Build the Open Alternative

ReplayCode is the **first and only open-source rebuild of Claude Code that actually runs**. We've proven the foundation works. Now we need the community to help push it forward.

⭐ **Star the repo**: [github.com/conghui/replaycode](https://github.com/conghui/replaycode)

**We're looking for contributors in:**
- **Interactive mode** — Get the Ink/React terminal UI working end-to-end
- **MCP support** — Connect to Model Context Protocol servers
- **Tool expansion** — Implement the 17 unreleased tools we've discovered in the source
- **Multi-agent** — Build out the coordinator/worker agent system
- **Testing** — Add comprehensive test coverage
- **Documentation** — Translate analysis reports, write tutorials

Whether you're a seasoned systems engineer or a curious student — if you want to understand how production agentic coding tools work from the inside out, **this is the project to contribute to**.

---

*Disclaimer: All source code is the intellectual property of Anthropic. This project is for research and educational purposes only. Commercial use is prohibited.*
