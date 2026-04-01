# ReplayCode

**首个可运行的 Claude Code 开源重建版本。**

我们从 Anthropic Claude Code CLI (v2.1.88) 的反编译 TypeScript 源码出发，使用标准 Node.js 工具链重建了整个构建流程，生成了一个**完全可运行的 CLI** — 支持 API 调用、工具执行和多轮代理对话。无需 Bun。

```bash
$ node dist/cli.cjs --version
2.1.88 (Claude Code)

$ node dist/cli.cjs -p "What is 2+2?"
4
```

**当前能力：等价于 Claude Code v2.1.88** | 9/9 自动化测试通过 | 40+ 工具可用

> **免责声明**: 本仓库中所有源码版权归 **Anthropic 和 Claude** 所有。本仓库仅用于技术研究和科研爱好者交流学习参考，**严禁任何个人、机构及组织将其用于商业用途、盈利性活动、非法用途及其他未经授权的场景。** 若内容涉及侵犯您的合法权益，请及时联系我们，我们将第一时间核实并予以删除处理。

**语言**: [English](README.md) | **中文**

---

## 快速开始

```bash
# 前置条件：Node.js >= 18
git clone https://github.com/conghui/replaycode.git
cd replaycode
npm install

# 构建（esbuild，约 15 秒）
npm run build              # → dist/cli.cjs (26.5MB)

# 验证
bash scripts/verify.sh     # → 9/9 测试通过

# 运行
export ANTHROPIC_API_KEY=sk-ant-...
node dist/cli.cjs -p "Hello, Claude!"
node dist/cli.cjs -p "List all .ts files in src/" --dangerously-skip-permissions
```

详细构建选项请参阅 [QUICKSTART.md](QUICKSTART.md)。

---

## 已验证功能

| 类别 | 功能 | 状态 |
|------|------|------|
| **CLI** | `--version`、`--help` | 可用 |
| **CLI** | `-p` / `--print`（headless 模式） | 可用 |
| **CLI** | `--output-format json` | 可用 |
| **CLI** | `--system-prompt` | 可用 |
| **CLI** | `--dangerously-skip-permissions` | 可用 |
| **工具** | Bash（Shell 命令执行） | 可用 |
| **工具** | FileRead（读取文件） | 可用 |
| **工具** | FileWrite（创建/写入文件） | 可用 |
| **工具** | FileEdit（编辑文件） | 可用 |
| **工具** | Grep（搜索文件内容） | 可用 |
| **工具** | Glob（按模式查找文件） | 可用 |
| **工具** | WebFetch（HTTP 请求） | 可用 |
| **API** | 流式响应 | 可用 |
| **API** | 工具调用 / 函数调用 | 可用 |
| **API** | 多轮对话 | 可用 |
| **API** | 成本追踪 & Token 使用量 | 可用 |

### 尚未可用

- 交互式 REPL 模式（需要 Ink/React 终端 UI）
- MCP 服务器连接
- 语法高亮 diff 显示（原生 `color-diff-napi` 已 stub）
- 图像处理（`sharp` 已 stub）
- OAuth 登录流程

---

## Showcase：自主完成任务

重建后的 CLI 能自主从零构建一个完整的天气工具：

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

Claude Code 自主完成：检查目录 → 创建 `package.json` → 编写 `src/weather.mjs` → 运行 → 报告 "北京 16°C，晴"。生成的代码可独立运行：

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

## 我们在哪里 — 以及我们要去哪里

ReplayCode 当前实现了 **Claude Code v2.1.88**（2025 年 5 月）的完整功能集。那时候 Claude Code 已经拥有 40+ 内置工具、多轮代理循环、完整权限模型和成本追踪。

官方 Claude Code 一直在快速进化 — 更新版本增加了交互式 REPL 改进、MCP 服务器支持、增强的多代理协调、语音模式等。**v2.1.88 与最新版之间的差距，就是社区的机会。**

### 路线图

| 优先级 | 功能 | 状态 |
|--------|------|------|
| P0 | 交互式 REPL 模式（Ink/React 终端 UI） | 未开始 |
| P0 | MCP 服务器连接 | 未开始 |
| P1 | 完整的插件/技能系统 | 未开始 |
| P1 | 多代理协调器模式 | 已 Stub |
| P2 | 语音模式（按键通话） | 已 Stub |
| P2 | KAIROS 自主代理模式 | 已 Stub |

---

## 深度分析文档 (`docs/`)

基于 v2.1.88 反编译源码的分析报告，中英双语。

```
docs/
├── en/                                        # English
│   ├── 01-telemetry-and-privacy.md           # 遥测与隐私
│   ├── 02-hidden-features-and-codenames.md   # 代号与 Feature Flag
│   ├── 03-undercover-mode.md                 # 卧底模式
│   ├── 04-remote-control-and-killswitches.md # 远程控制与紧急开关
│   └── 05-future-roadmap.md                  # 未来路线图
│
└── zh/                                        # 中文
    ├── 01-遥测与隐私分析.md
    ├── 02-隐藏功能与模型代号.md
    ├── 03-卧底模式分析.md
    ├── 04-远程控制与紧急开关.md
    └── 05-未来路线图.md
```

| # | 主题 | 核心发现 |
|---|------|---------|
| 01 | **遥测与隐私** | 双层分析管道（1P→Anthropic, Datadog）。每个事件携带环境指纹。**无用户退出开关**。 |
| 02 | **隐藏功能与代号** | 动物代号体系（Capybara/Tengu/Fennec/Numbat）。Feature flag 用随机词对掩盖用途。隐藏命令：`/btw`、`/stickers`。 |
| 03 | **卧底模式** | Anthropic 员工在公开仓库自动进入卧底模式。模型指令："**不要暴露你的掩护身份**"。**没有强制关闭选项。** |
| 04 | **远程控制** | 每小时拉取配置。6+ 紧急开关。GrowthBook 可无同意改变任何用户行为。 |
| 05 | **未来路线图** | **Numbat** 下一代代号。**KAIROS** = 自主代理模式，含心跳、推送通知、PR 订阅。发现 17 个未上线工具。 |

---

## 构建原理

构建需要解决从反编译源码重建可运行 CLI 的多项挑战：

| 挑战 | 解决方案 |
|------|---------|
| **108 个缺失的 feature-gated 模块** | 智能 stub 生成：解析 esbuild 错误 → 解析导入路径 → 生成类型正确的 stub |
| **`feature()` 来自 `bun:bundle`** | 移除 import 语句，通过 `--banner:js` 注入 `feature()` → `false` |
| **ESM/CJS 互操作** | 将所有依赖打包为单个 CJS 文件 |
| **CJS 中的 `import.meta.url`** | 构建时转换 → `__filename` |
| **Anthropic 内部包** | 创建正确导出的本地 stub |
| **原生 NAPI 模块** | 纯 JS 替代实现（`color-diff-napi`、`sharp`） |
| **MACRO 编译时常量** | 字符串替换：`MACRO.VERSION` → `'2.1.88'` |

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────────────┐
│                         入口层                                      │
│  cli.tsx ──> main.tsx ──> REPL.tsx (交互式)                        │
│                     └──> QueryEngine.ts (headless/SDK)              │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       查询引擎                                      │
│  submitMessage(prompt) ──> AsyncGenerator<SDKMessage>               │
│    ├── fetchSystemPromptParts()    ──> 组装系统提示词               │
│    ├── processUserInput()          ──> 处理 /命令                   │
│    ├── query()                     ──> 主代理循环                   │
│    │     ├── StreamingToolExecutor ──> 并行工具执行                  │
│    │     ├── autoCompact()         ──> 上下文压缩                   │
│    │     └── runTools()            ──> 工具编排                     │
│    └── yield SDKMessage            ──> 流式传输给消费者             │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
┌──────────────────┐ ┌─────────────────┐ ┌──────────────────┐
│   工具系统        │ │  服务层         │ │   状态层          │
│                  │ │                 │ │                  │
│ 40+ 内置工具:    │ │ api/claude.ts   │ │ AppState Store   │
│  ├─ BashTool     │ │ compact/        │ │  ├─ permissions  │
│  ├─ FileRead     │ │ mcp/            │ │  ├─ fileHistory  │
│  ├─ FileEdit     │ │ analytics/      │ │  └─ fastMode     │
│  ├─ Glob/Grep    │ │ tools/executor  │ │                  │
│  ├─ AgentTool    │ │ plugins/        │ │ React Context    │
│  ├─ WebFetch     │ │ settingsSync/   │ │  ├─ useAppState  │
│  └─ MCPTool      │ │ oauth/          │ │  └─ useSetState  │
└──────────────────┘ └─────────────────┘ └──────────────────┘
```

### 代理循环

```
    用户 --> messages[] --> Claude API --> 响应
                                          |
                                stop_reason == "tool_use"?
                               /                          \
                             是                           否
                              |                             |
                        执行工具                        返回文本
                        追加 tool_result
                        循环回退 -----------------> messages[]
```

---

## 12 层渐进式线束机制

本源码展示了生产级 AI 代理线束在基本循环之上需要的 12 层机制：

| # | 机制 | 关键洞察 |
|---|------|---------|
| s01 | **循环** | `query.ts`：while-true 循环调用 Claude API、检查 stop_reason、执行工具 |
| s02 | **工具分发** | `Tool.ts` + `tools.ts`：添加工具 = 添加一个处理器。循环保持不变 |
| s03 | **规划** | `EnterPlanModeTool` + `TodoWriteTool`：先列步骤，再执行 |
| s04 | **子代理** | `AgentTool` + `forkSubagent.ts`：每个子代理获得独立的 messages[] |
| s05 | **按需知识** | `SkillTool` + `memdir/`：通过 tool_result 注入，而非系统提示 |
| s06 | **上下文压缩** | `services/compact/`：autoCompact + snipCompact + contextCollapse |
| s07 | **持久化任务** | `TaskCreate/Update/Get/List`：基于文件的任务图 |
| s08 | **后台任务** | `DreamTask` + `LocalShellTask`：守护线程，完成时注入通知 |
| s09 | **代理团队** | `TeamCreate/Delete` + `InProcessTeammateTask`：持久化队友 |
| s10 | **团队协议** | `SendMessageTool`：统一的请求-响应模式 |
| s11 | **自主代理** | `coordinator/coordinatorMode.ts`：空闲周期 + 自动认领任务 |
| s12 | **工作树隔离** | `EnterWorktreeTool/ExitWorktreeTool`：每个代理在独立目录工作 |

---

## 目录参考

```
replaycode/
├── src/                     # 原始 TypeScript 源码（1,884 文件，512K 行代码）
│   ├── main.tsx             #   REPL 引导程序
│   ├── QueryEngine.ts       #   SDK/headless 查询生命周期引擎
│   ├── query.ts             #   主代理循环（785KB，最大文件）
│   ├── Tool.ts              #   工具接口 + buildTool 工厂
│   ├── tools.ts             #   工具注册、预设、过滤
│   ├── commands.ts          #   斜杠命令定义（80+）
│   ├── entrypoints/         #   应用入口点
│   ├── commands/            #   斜杠命令实现
│   ├── components/          #   React/Ink 终端 UI
│   ├── services/            #   业务逻辑（API、MCP、压缩、分析）
│   ├── state/               #   应用状态（Zustand + React context）
│   ├── tasks/               #   任务实现（shell、代理、dream）
│   ├── tools/               #   40+ 工具实现
│   ├── utils/               #   工具函数（最大目录）
│   └── vendor/              #   原生模块源码 stub
│
├── scripts/                 # 构建 & 验证
│   ├── build.mjs            #   esbuild 打包脚本
│   ├── prepare-src.mjs      #   源码预处理（feature gate、MACRO）
│   ├── transform.mjs        #   AST 转换
│   ├── stub-modules.mjs     #   108 个缺失模块的 stub 生成器
│   └── verify.sh            #   9 项自动化验证套件
│
├── stubs/                   # Bun 编译时内建函数的构建 stub
├── docs/                    # 深度分析报告（中英双语）
├── dist/                    # 构建输出（npm run build 生成）
├── ANNOUNCEMENT.md          # 发布公告帖
├── RELEASE.md               # 完整技术发布文档
├── QUICKSTART.md            # 构建 & 运行指南
└── CLAUDE.md                # Claude Code 项目指令
```

---

## 统计数据

| 项目 | 数量 |
|------|------|
| 源文件 (.ts/.tsx) | ~1,884 |
| 代码行数 | ~512,664 |
| 最大单文件 | `query.ts` (~785KB) |
| 内置工具 | ~40+ |
| 斜杠命令 | ~80+ |
| 依赖包 | ~192 个 |
| 构建产物 | `dist/cli.cjs` (26.5MB) |
| 构建时间 | ~15 秒 |

---

## 缺失模块（108 个）

108 个被 `feature()` 门控的模块**未包含**在 npm 包中。它们仅存在于 Anthropic 的内部 monorepo 中，在编译时被死代码消除。

<details>
<summary>Anthropic 内部代码（~70 个模块）— 点击展开</summary>

| 模块 | 用途 | Feature Gate |
|------|------|-------------|
| `daemon/main.js` | 后台守护进程管理器 | `DAEMON` |
| `proactive/index.js` | 主动通知系统 | `PROACTIVE` |
| `contextCollapse/index.js` | 上下文折叠服务 | `CONTEXT_COLLAPSE` |
| `skillSearch/*.js` | 远程技能搜索（6 个模块） | `EXPERIMENTAL_SKILL_SEARCH` |
| `coordinator/workerAgent.js` | 多代理协调器 | `COORDINATOR_MODE` |
| `bridge/peerSessions.js` | 桥接对等会话 | `BRIDGE_MODE` |
| `assistant/*.js` | KAIROS 助手模式 | `KAIROS` |
| `compact/reactiveCompact.js` | 响应式上下文压缩 | `CACHED_MICROCOMPACT` |
| `compact/snipCompact.js` | 基于裁剪的压缩 | `HISTORY_SNIP` |
| `commands/buddy/index.js` | Buddy 系统通知 | `BUDDY` |
| `commands/fork/index.js` | Fork 子代理 | `FORK_SUBAGENT` |
| `commands/subscribe-pr.js` | GitHub PR 订阅 | `KAIROS_GITHUB_WEBHOOKS` |
| `commands/workflows/index.js` | 工作流命令 | `WORKFLOW_SCRIPTS` |
| ... 以及约 55 个更多模块 | | |

</details>

<details>
<summary>Feature-Gated 工具（~17 个模块）— 点击展开</summary>

| 工具 | 用途 | Feature Gate |
|------|------|-------------|
| `REPLTool` | 交互式 REPL（VM 沙箱） | `ant`（内部） |
| `SleepTool` | 代理循环中的休眠/延迟 | `PROACTIVE` / `KAIROS` |
| `WebBrowserTool` | 浏览器自动化 | `WEB_BROWSER_TOOL` |
| `WorkflowTool` | 工作流执行 | `WORKFLOW_SCRIPTS` |
| `MonitorTool` | MCP 监控 | `MONITOR_TOOL` |
| `PushNotificationTool` | 推送通知 | `KAIROS` |
| `SubscribePRTool` | GitHub PR 订阅 | `KAIROS_GITHUB_WEBHOOKS` |
| `DiscoverSkillsTool` | 技能发现 | `EXPERIMENTAL_SKILL_SEARCH` |
| ... 以及约 9 个更多工具 | | |

</details>

**为什么缺失**: Bun 的 `feature()` 是编译时内建函数。在 Anthropic 内部构建中返回 `true`（代码保留），在发布构建中返回 `false`（代码被消除）。这 108 个模块在已发布的 npm 制品中根本不存在。

---

## 参与贡献

ReplayCode 是首个也是唯一一个可运行的 Claude Code 开源重建版本。我们已经证明基础可行。现在需要社区共同推进。

我们正在寻找以下方向的贡献者：
- **交互模式** — 实现 Ink/React 终端 UI 的端到端功能
- **MCP 支持** — 连接 Model Context Protocol 服务器
- **工具扩展** — 实现源码中发现的 17 个未上线工具
- **多代理** — 构建协调器/工作代理系统
- **测试** — 添加全面的测试覆盖
- **文档** — 翻译分析报告，撰写教程

详情请参阅 [ANNOUNCEMENT.md](ANNOUNCEMENT.md)。

---

## 许可证

本仓库中所有源码版权归 **Anthropic 和 Claude** 所有。本仓库仅用于技术研究和教育目的。完整许可条款请参阅原始 npm 包。
