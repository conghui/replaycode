# ReplayCode

**The first open-source rebuild of Claude Code that actually runs.**

We took the decompiled TypeScript source of Anthropic's Claude Code CLI (v2.1.88), reconstructed the build pipeline with standard Node.js tooling, and produced a **fully functional CLI** — complete with API calls, tool execution, and multi-turn agentic conversations. No Bun required.

```bash
$ node dist/cli.cjs --version
2.1.88 (Claude Code)

$ node dist/cli.cjs -p "What is 2+2?"
4
```

**Current capability: equivalent to Claude Code v2.1.88** | 9/9 automated tests passing | 40+ tools working

> **Disclaimer**: All source code in this repository is the intellectual property of **Anthropic and Claude**. This repository is provided strictly for technical research, study, and educational exchange among enthusiasts. **Commercial use is strictly prohibited.** If any content infringes upon your rights, please contact us for immediate removal.

**Language**: **English** | [中文](README_CN.md)

---

## Quick Start

```bash
# Prerequisites: Node.js >= 18
git clone https://github.com/conghui/replaycode.git
cd replaycode
npm install

# Build (esbuild, ~15 seconds)
npm run build              # → dist/cli.cjs (26.5MB)

# Verify
bash scripts/verify.sh     # → 9/9 tests passing

# Run
export ANTHROPIC_API_KEY=sk-ant-...
node dist/cli.cjs -p "Hello, Claude!"
node dist/cli.cjs -p "List all .ts files in src/" --dangerously-skip-permissions
```

See [QUICKSTART.md](QUICKSTART.md) for detailed build options.

---

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

---

## Showcase: Autonomous Task Completion

The rebuilt CLI autonomously builds a complete weather tool from scratch:

```bash
$ node dist/cli.cjs -p "
  Build a Node.js CLI weather tool:
  1. Create package.json (name: weather-cli, type: module)
  2. Create src/weather.mjs: takes city as argv,
     fetches https://wttr.in/{city}?format=j1,
     prints formatted weather (temp, humidity, wind, description)
  3. Run it with: node src/weather.mjs Beijing
" --dangerously-skip-permissions
```

Claude Code autonomously: inspected directory → created `package.json` → wrote `src/weather.mjs` → ran it → reported "Beijing is 16°C and sunny". The generated code runs independently:

```
$ node src/weather.mjs Tokyo

  Weather for Tokyo
  ──────────────────────────────
  Temperature : 17°C
  Humidity    : 88%
  Wind        : 18 km/h NW
  Description : Light rain
```

---

## Where We Are — and Where We're Going

ReplayCode currently implements the full feature set of **Claude Code v2.1.88** (May 2025). At that point, Claude Code already had 40+ built-in tools, multi-turn agentic loop with streaming, full permission model, and cost tracking.

The official Claude Code has continued evolving rapidly — newer versions have added interactive REPL improvements, MCP server support, enhanced multi-agent coordination, voice mode, and more. **The gap between v2.1.88 and the latest Claude Code is our opportunity.**

### Roadmap

| Priority | Feature | Status |
|----------|---------|--------|
| P0 | Interactive REPL mode (Ink/React terminal UI) | Not started |
| P0 | MCP server connections | Not started |
| P1 | Full plugin/skill system | Not started |
| P1 | Multi-agent coordinator mode | Stubbed |
| P2 | Voice mode (push-to-talk) | Stubbed |
| P2 | KAIROS autonomous agent mode | Stubbed |

---

## Deep Analysis Reports (`docs/`)

Source code analysis reports derived from decompiled v2.1.88. Bilingual (EN/ZH).

```
docs/
├── en/                                        # English
│   ├── 01-telemetry-and-privacy.md           # Telemetry & Privacy
│   ├── 02-hidden-features-and-codenames.md   # Codenames & Feature Flags
│   ├── 03-undercover-mode.md                 # Undercover Mode
│   ├── 04-remote-control-and-killswitches.md # Remote Control & Killswitches
│   └── 05-future-roadmap.md                  # Future Roadmap
│
└── zh/                                        # 中文
    ├── 01-遥测与隐私分析.md
    ├── 02-隐藏功能与模型代号.md
    ├── 03-卧底模式分析.md
    ├── 04-远程控制与紧急开关.md
    └── 05-未来路线图.md
```

| # | Topic | Key Findings |
|---|-------|-------------|
| 01 | **Telemetry & Privacy** | Two analytics sinks (1P → Anthropic, Datadog). Environment fingerprint on every event. **No UI-exposed opt-out**. |
| 02 | **Hidden Features & Codenames** | Animal codenames (Capybara/Tengu/Fennec/Numbat). Feature flags use random word pairs to obscure purpose. Hidden commands: `/btw`, `/stickers`. |
| 03 | **Undercover Mode** | Anthropic employees auto-enter undercover mode in public repos. Model instructed: *"Do not blow your cover."* **No force-OFF exists.** |
| 04 | **Remote Control** | Hourly polling of settings. 6+ killswitches. GrowthBook flags can change any user's behavior without consent. |
| 05 | **Future Roadmap** | **Numbat** next codename. **KAIROS** = autonomous agent with heartbeats, push notifications, PR subscriptions. 17 unreleased tools found. |

---

## How the Build Works

The build solves several challenges in reconstructing a working CLI from decompiled source:

| Challenge | Solution |
|-----------|----------|
| **108 missing feature-gated modules** | Smart stub generation: parse esbuild errors, resolve imports, generate type-correct stubs |
| **`feature()` from `bun:bundle`** | Remove imports, provide `feature()` → `false` via `--banner:js` |
| **ESM/CJS interop** | Bundle ALL packages into one CJS file |
| **`import.meta.url` in CJS** | Build-time transform → `__filename` |
| **Internal Anthropic packages** | Local stubs with correct exports |
| **Native NAPI modules** | Pure JS stub replacements (`color-diff-napi`, `sharp`) |
| **MACRO compile-time constants** | String replacement: `MACRO.VERSION` → `'2.1.88'` |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         ENTRY LAYER                                 │
│  cli.tsx ──> main.tsx ──> REPL.tsx (interactive)                   │
│                     └──> QueryEngine.ts (headless/SDK)              │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       QUERY ENGINE                                  │
│  submitMessage(prompt) ──> AsyncGenerator<SDKMessage>               │
│    ├── fetchSystemPromptParts()    ──> assemble system prompt       │
│    ├── processUserInput()          ──> handle /commands             │
│    ├── query()                     ──> main agent loop              │
│    │     ├── StreamingToolExecutor ──> parallel tool execution       │
│    │     ├── autoCompact()         ──> context compression          │
│    │     └── runTools()            ──> tool orchestration           │
│    └── yield SDKMessage            ──> stream to consumer           │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
┌──────────────────┐ ┌─────────────────┐ ┌──────────────────┐
│   TOOL SYSTEM    │ │  SERVICE LAYER  │ │   STATE LAYER    │
│                  │ │                 │ │                  │
│ 40+ Built-in:    │ │ api/claude.ts   │ │ AppState Store   │
│  ├─ BashTool     │ │ compact/        │ │  ├─ permissions  │
│  ├─ FileRead     │ │ mcp/            │ │  ├─ fileHistory  │
│  ├─ FileEdit     │ │ analytics/      │ │  └─ fastMode     │
│  ├─ Glob/Grep    │ │ tools/executor  │ │                  │
│  ├─ AgentTool    │ │ plugins/        │ │ React Context    │
│  ├─ WebFetch     │ │ settingsSync/   │ │  ├─ useAppState  │
│  └─ MCPTool      │ │ oauth/          │ │  └─ useSetState  │
└──────────────────┘ └─────────────────┘ └──────────────────┘
```

### The Agent Loop

```
    User --> messages[] --> Claude API --> response
                                          |
                                stop_reason == "tool_use"?
                               /                          \
                             yes                           no
                              |                             |
                        execute tools                    return text
                        append tool_result
                        loop back -----------------> messages[]
```

This is the minimal agent loop. Claude Code wraps it with a production-grade harness: permissions, streaming, concurrency, compaction, sub-agents, persistence, and MCP.

---

## The 12 Progressive Harness Mechanisms

This source code demonstrates 12 layered mechanisms that a production AI agent harness needs beyond the basic loop:

| # | Mechanism | Key Insight |
|---|-----------|-------------|
| s01 | **The Loop** | `query.ts`: while-true loop calling Claude API, checking stop_reason, executing tools |
| s02 | **Tool Dispatch** | `Tool.ts` + `tools.ts`: adding a tool = adding one handler. Loop stays identical |
| s03 | **Planning** | `EnterPlanModeTool` + `TodoWriteTool`: list steps first, then execute |
| s04 | **Sub-Agents** | `AgentTool` + `forkSubagent.ts`: each child gets fresh messages[] |
| s05 | **Knowledge on Demand** | `SkillTool` + `memdir/`: inject via tool_result, not system prompt |
| s06 | **Context Compression** | `services/compact/`: autoCompact + snipCompact + contextCollapse |
| s07 | **Persistent Tasks** | `TaskCreate/Update/Get/List`: file-based task graph with status tracking |
| s08 | **Background Tasks** | `DreamTask` + `LocalShellTask`: daemon threads, inject notifications |
| s09 | **Agent Teams** | `TeamCreate/Delete` + `InProcessTeammateTask`: persistent teammates |
| s10 | **Team Protocols** | `SendMessageTool`: one request-response pattern for all agent negotiation |
| s11 | **Autonomous Agents** | `coordinator/coordinatorMode.ts`: idle cycle + auto-claim tasks |
| s12 | **Worktree Isolation** | `EnterWorktreeTool/ExitWorktreeTool`: each agent works in its own directory |

---

## Complete Tool Inventory

```
    FILE OPERATIONS          SEARCH & DISCOVERY        EXECUTION
    ═════════════════        ══════════════════════     ══════════
    FileReadTool             GlobTool                  BashTool
    FileEditTool             GrepTool                  PowerShellTool
    FileWriteTool            ToolSearchTool
    NotebookEditTool                                   INTERACTION
                                                       ═══════════
    WEB & NETWORK           AGENT / TASK              AskUserQuestionTool
    ════════════════        ══════════════════        BriefTool
    WebFetchTool             AgentTool
    WebSearchTool            SendMessageTool           PLANNING & WORKFLOW
                             TeamCreateTool            ════════════════════
    MCP PROTOCOL             TeamDeleteTool            EnterPlanModeTool
    ══════════════           TaskCreateTool            ExitPlanModeTool
    MCPTool                  TaskGetTool               EnterWorktreeTool
    ListMcpResourcesTool     TaskUpdateTool            ExitWorktreeTool
    ReadMcpResourceTool      TaskListTool              TodoWriteTool
                             TaskStopTool
                             TaskOutputTool            SYSTEM
                                                       ════════
                             SKILLS & EXTENSIONS       ConfigTool
                             ═════════════════════     SkillTool
                             SkillTool                 ScheduleCronTool
                             LSPTool                   SleepTool
```

---

## Directory Reference

```
replaycode/
├── src/                     # Original TypeScript source (1,884 files, 512K LOC)
│   ├── main.tsx             #   REPL bootstrap
│   ├── QueryEngine.ts       #   SDK/headless query lifecycle engine
│   ├── query.ts             #   Main agent loop (785KB, largest file)
│   ├── Tool.ts              #   Tool interface + buildTool factory
│   ├── tools.ts             #   Tool registry, presets, filtering
│   ├── commands.ts          #   Slash command definitions (~80+)
│   ├── entrypoints/         #   Application entry points
│   ├── commands/            #   Slash command implementations
│   ├── components/          #   React/Ink terminal UI
│   ├── services/            #   Business logic (API, MCP, compact, analytics)
│   ├── state/               #   Application state (Zustand + React context)
│   ├── tasks/               #   Task implementations (shell, agent, dream)
│   ├── tools/               #   40+ tool implementations
│   ├── utils/               #   Utilities (largest directory)
│   └── vendor/              #   Native module source stubs
│
├── scripts/                 # Build & verification
│   ├── build.mjs            #   esbuild bundler script
│   ├── prepare-src.mjs      #   Source preprocessing (feature gates, MACRO)
│   ├── transform.mjs        #   AST transformations
│   ├── stub-modules.mjs     #   Stub generator for 108 missing modules
│   └── verify.sh            #   9-test automated verification suite
│
├── stubs/                   # Build stubs for Bun compile-time intrinsics
├── docs/                    # Deep analysis reports (EN/ZH)
├── dist/                    # Build output (created by npm run build)
├── ANNOUNCEMENT.md          # Release announcement post
├── RELEASE.md               # Full technical release document
├── QUICKSTART.md            # Build & run guide
└── CLAUDE.md                # Claude Code project instructions
```

---

## Stats

| Item | Count |
|------|-------|
| Source files (.ts/.tsx) | ~1,884 |
| Lines of code | ~512,664 |
| Largest single file | `query.ts` (~785KB) |
| Built-in tools | ~40+ |
| Slash commands | ~80+ |
| Dependencies | ~192 packages |
| Build output | `dist/cli.cjs` (26.5MB) |
| Build time | ~15 seconds |

---

## Missing Modules (108)

108 modules referenced by `feature()`-gated branches are **not included** in the npm package. They exist only in Anthropic's internal monorepo and were dead-code-eliminated at compile time.

<details>
<summary>Anthropic Internal Code (~70 modules) — click to expand</summary>

| Module | Purpose | Feature Gate |
|--------|---------|-------------|
| `daemon/main.js` | Background daemon supervisor | `DAEMON` |
| `proactive/index.js` | Proactive notification system | `PROACTIVE` |
| `contextCollapse/index.js` | Context collapse service | `CONTEXT_COLLAPSE` |
| `skillSearch/*.js` | Remote skill search (6 modules) | `EXPERIMENTAL_SKILL_SEARCH` |
| `coordinator/workerAgent.js` | Multi-agent coordinator | `COORDINATOR_MODE` |
| `bridge/peerSessions.js` | Bridge peer sessions | `BRIDGE_MODE` |
| `assistant/*.js` | KAIROS assistant mode | `KAIROS` |
| `compact/reactiveCompact.js` | Reactive context compaction | `CACHED_MICROCOMPACT` |
| `compact/snipCompact.js` | Snip-based compaction | `HISTORY_SNIP` |
| `commands/buddy/index.js` | Buddy system notifications | `BUDDY` |
| `commands/fork/index.js` | Fork subagent | `FORK_SUBAGENT` |
| `commands/subscribe-pr.js` | GitHub PR subscription | `KAIROS_GITHUB_WEBHOOKS` |
| `commands/workflows/index.js` | Workflow commands | `WORKFLOW_SCRIPTS` |
| ... and ~55 more | | |

</details>

<details>
<summary>Feature-Gated Tools (~17 modules) — click to expand</summary>

| Tool | Purpose | Feature Gate |
|------|---------|-------------|
| `REPLTool` | Interactive REPL (VM sandbox) | `ant` (internal) |
| `SleepTool` | Sleep/delay in agent loop | `PROACTIVE` / `KAIROS` |
| `WebBrowserTool` | Browser automation | `WEB_BROWSER_TOOL` |
| `WorkflowTool` | Workflow execution | `WORKFLOW_SCRIPTS` |
| `MonitorTool` | MCP monitoring | `MONITOR_TOOL` |
| `PushNotificationTool` | Push notifications | `KAIROS` |
| `SubscribePRTool` | GitHub PR subscription | `KAIROS_GITHUB_WEBHOOKS` |
| `DiscoverSkillsTool` | Skill discovery | `EXPERIMENTAL_SKILL_SEARCH` |
| ... and ~9 more | | |

</details>

**Why they're missing**: Bun's `feature()` is a compile-time intrinsic. Returns `true` in Anthropic's internal build (code kept), returns `false` in the published build (code eliminated). These 108 modules simply do not exist in the published npm artifact.

---

## Contributing

ReplayCode is the first and only open-source rebuild of Claude Code that actually runs. We've proven the foundation works. Now we need the community to help push it forward.

We're looking for contributors in:
- **Interactive mode** — Get the Ink/React terminal UI working end-to-end
- **MCP support** — Connect to Model Context Protocol servers
- **Tool expansion** — Implement the 17 unreleased tools discovered in the source
- **Multi-agent** — Build out the coordinator/worker agent system
- **Testing** — Add comprehensive test coverage
- **Documentation** — Translate analysis reports, write tutorials

See [ANNOUNCEMENT.md](ANNOUNCEMENT.md) for the full story and roadmap.

---

## License

All source code in this repository is copyright **Anthropic and Claude**. This repository is for technical research and education only. See the original npm package for full license terms.
