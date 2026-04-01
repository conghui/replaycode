# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Decompiled TypeScript source of Claude Code v2.1.88, extracted from the npm package `@anthropic-ai/claude-code`. The published package ships a single bundled `cli.js` (~12MB); `src/` contains the unbundled source (~1,884 files). This repo is for research/study only — it is **not** a buildable product repo in the traditional sense.

## Build & Run Commands

```bash
npm install                    # Install dependencies (esbuild, typescript)
npm run build                  # Best-effort build: prepare-src + esbuild bundle → dist/cli.js
npm run check                  # TypeScript type-check (no emit)
npm run prepare-src            # Just the source transformation step
node dist/cli.js               # Run the built CLI
```

The build is **best-effort** — it cannot fully replicate Bun's compile-time intrinsics (`feature()`, `MACRO`, `bun:bundle`). 108 feature-gated internal modules are missing and get stubbed out. The build script transforms `feature('X')` → `false` and `MACRO.VERSION` → `'2.1.88'` before bundling with esbuild.

There are no tests in this repository.

## Architecture

### Entry & Bootstrap

`src/entrypoints/cli.tsx` → fast-path version/help checks → `src/main.tsx` → full initialization (system prompts, commands, tools, MCP config). Startup is optimized with profiling checkpoints and parallel prefetching.

### Core Loop

`QueryEngine.ts` manages the per-conversation multi-turn loop via `submitMessage()`. The `query()` generator in `query.ts` orchestrates the actual LLM interaction: building messages, executing tools, managing context compaction, token budgets, and streaming.

### Tool System

`Tool.ts` defines the tool interface. `tools.ts` is the registry that conditionally loads 45+ tools (Bash, FileEdit, FileRead, Glob, Grep, Agent, Skill, Task, Team, MCP, WebSearch, LSP, etc.) with feature-gate filtering and permission checks. Each tool lives in its own directory under `tools/` (e.g., `tools/BashTool/`).

### Commands & Skills

`commands.ts` registers 100+ user-invocable commands. Skills (`skills/`) are prompt-based commands with lazy-loaded file support; bundled skills are registered via `registerBundledSkill()` and user-defined skills are discovered from `.claude/skills/`.

### Services

Key service directories under `services/`:
- `api/` — Claude API communication and bootstrap data
- `analytics/` — Event logging, GrowthBook feature flags, telemetry
- `mcp/` — Model Context Protocol client/server registry
- `compact/` — Auto-compaction and message summarization
- `tools/` — Streaming tool executor and orchestration
- `plugins/` — Plugin loading and command extraction
- `policyLimits/` — Rate limiting and quota enforcement

### State Management

`state/AppState.tsx` wraps React context with a Zustand-based store (`AppStateStore.ts`). Holds permission contexts, tool settings, file caches, notifications, and UI state. The CLI uses Ink (React-based terminal UI).

### Coordinator / Multi-Agent

`coordinator/coordinatorMode.ts` enables multi-agent orchestration, gating whether spawned agents get full or restricted tool access. Feature-gated via `COORDINATOR_MODE`.

## Key Patterns

- **Feature gates**: `feature('FLAG_NAME')` from `bun:bundle` — resolved at Bun compile time. In this repo, all are stubbed to `false`, so feature-gated code paths are dead code.
- **MACRO constants**: `MACRO.VERSION`, `MACRO.BUILD_ID`, etc. — Bun compile-time defines, replaced by `scripts/build.mjs`.
- **Stubs**: `stubs/bun-bundle.ts` provides the `feature()` stub; `stubs/macros.ts` provides MACRO constants; `vendor/` contains native module stubs (e.g., `bun:ffi`).
- **Path aliases**: `bun:bundle` → `stubs/bun-bundle.ts`, `src/*` → `src/*` (configured in `tsconfig.json`).
