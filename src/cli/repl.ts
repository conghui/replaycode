/**
 * Readline-based interactive REPL for ReplayCode.
 *
 * Replaces Ink (React terminal UI) with a simple readline interface
 * so the CLI works under Node.js (esbuild build) without Bun.
 */
import * as readline from 'node:readline'
import chalk from 'chalk'
import { ask } from 'src/QueryEngine.js'
import { createAbortController } from 'src/utils/abortController.js'
import { getCwd } from 'src/utils/cwd.js'
import {
  createFileStateCacheWithSizeLimit,
  READ_FILE_STATE_CACHE_SIZE,
} from 'src/utils/fileStateCache.js'
import type { AppState } from 'src/state/AppState.js'
import type { Tools } from 'src/Tool.js'
import type { Command } from 'src/commands.js'
import type { AgentDefinition } from 'src/tools/AgentTool/loadAgentsDir.js'
import type { McpSdkServerConfig, MCPServerConnection } from 'src/services/mcp/types.js'
import type { CanUseToolFn } from 'src/hooks/useCanUseTool.js'
import type { ThinkingConfig } from 'src/utils/thinking.js'
import type { Message } from 'src/types/message.js'
import type { FileStateCache } from 'src/utils/fileStateCache.js'

export interface ReplOptions {
  tools: Tools
  commands: Command[]
  sdkMcpConfigs: Record<string, McpSdkServerConfig>
  agents: AgentDefinition[]
  getAppState: () => AppState
  setAppState: (f: (prev: AppState) => AppState) => void
  canUseTool: CanUseToolFn
  thinkingConfig?: ThinkingConfig
  userSpecifiedModel?: string
  systemPrompt?: string
  appendSystemPrompt?: string
  verbose?: boolean
  maxTurns?: number
  maxBudgetUsd?: number
}

export async function runInteractiveRepl(options: ReplOptions): Promise<void> {
  const {
    tools,
    commands,
    agents,
    getAppState,
    setAppState,
    canUseTool,
    thinkingConfig,
    userSpecifiedModel,
    systemPrompt,
    appendSystemPrompt,
    verbose,
    maxTurns,
    maxBudgetUsd,
  } = options

  // Persistent conversation state across turns
  const mutableMessages: Message[] = []
  let readFileState: FileStateCache = createFileStateCacheWithSizeLimit(
    READ_FILE_STATE_CACHE_SIZE,
  )

  // Current abort controller for the running turn
  let currentAbort: AbortController | null = null

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    prompt: chalk.green('> '),
    historySize: 200,
  })

  // Handle Ctrl+C: abort current turn or exit if idle
  let isRunning = false
  rl.on('SIGINT', () => {
    if (isRunning && currentAbort) {
      currentAbort.abort()
      process.stdout.write('\n' + chalk.yellow('[Aborted]') + '\n')
      isRunning = false
      rl.prompt()
    } else {
      // Double Ctrl+C when idle → exit
      process.stdout.write('\n')
      process.exit(0)
    }
  })

  // Greeting
  process.stdout.write(
    chalk.bold('ReplayCode') +
      chalk.dim(' (readline REPL)') +
      '\n' +
      chalk.dim('Type your message, or "exit" / Ctrl+D to quit.') +
      '\n\n',
  )

  rl.prompt()

  for await (const line of rl) {
    const input = line.trim()
    if (!input) {
      rl.prompt()
      continue
    }
    if (input === 'exit' || input === 'quit') {
      break
    }

    isRunning = true
    currentAbort = createAbortController()

    try {
      const appState = getAppState()
      const mcpClients: MCPServerConnection[] = appState.mcp?.clients ?? []

      // Stream responses from ask()
      let gotText = false
      for await (const message of ask({
        commands,
        prompt: input,
        cwd: getCwd(),
        tools,
        verbose: verbose ?? false,
        mcpClients,
        thinkingConfig,
        maxTurns,
        maxBudgetUsd,
        canUseTool,
        mutableMessages,
        getReadFileCache: () => readFileState,
        setReadFileCache: (cache: FileStateCache) => {
          readFileState = cache
        },
        customSystemPrompt: systemPrompt,
        appendSystemPrompt,
        userSpecifiedModel,
        getAppState,
        setAppState,
        abortController: currentAbort,
        agents,
      })) {
        if (currentAbort.signal.aborted) break

        if (message.type === 'assistant') {
          // Process content blocks
          const content = (message as any).message?.content
          if (Array.isArray(content)) {
            for (const block of content) {
              if (block.type === 'text' && block.text) {
                process.stdout.write(block.text)
                gotText = true
              } else if (block.type === 'tool_use') {
                if (gotText) {
                  process.stdout.write('\n')
                  gotText = false
                }
                const toolName = block.name ?? 'unknown'
                const briefInput = summarizeToolInput(block.input)
                process.stdout.write(
                  chalk.yellow(`[Tool: ${toolName}]`) +
                    (briefInput ? ' ' + chalk.dim(briefInput) : '') +
                    '\n',
                )
              }
            }
          }
        } else if (message.type === 'result') {
          if (gotText) {
            process.stdout.write('\n')
            gotText = false
          }
          const m = message as any
          if (m.subtype === 'success') {
            const cost =
              typeof m.total_cost_usd === 'number'
                ? `$${m.total_cost_usd.toFixed(4)}`
                : ''
            const turns =
              typeof m.num_turns === 'number' ? `${m.num_turns} turns` : ''
            const parts = [turns, cost].filter(Boolean).join(', ')
            if (parts) {
              process.stdout.write(chalk.dim(`[${parts}]`) + '\n')
            }
          } else if (m.subtype === 'error_during_execution') {
            const errors = Array.isArray(m.errors)
              ? m.errors.join('; ')
              : 'unknown error'
            process.stdout.write(chalk.red(`[Error] ${errors}`) + '\n')
          } else if (m.subtype === 'error_max_turns') {
            process.stdout.write(
              chalk.red(`[Error] Reached max turns`) + '\n',
            )
          }
        }
        // Skip other message types (system, user, etc.)
      }

      // Ensure trailing newline
      if (gotText) {
        process.stdout.write('\n')
      }
    } catch (err: any) {
      if (err?.name !== 'AbortError') {
        process.stderr.write(
          chalk.red(`[Error] ${err?.message ?? String(err)}`) + '\n',
        )
      }
    } finally {
      isRunning = false
      currentAbort = null
    }

    process.stdout.write('\n')
    rl.prompt()
  }

  // Clean exit
  rl.close()
  process.exit(0)
}

/**
 * Summarize tool input for display — show first key=value pairs, truncated.
 */
function summarizeToolInput(input: unknown): string {
  if (!input || typeof input !== 'object') return ''
  const entries = Object.entries(input as Record<string, unknown>)
  if (entries.length === 0) return ''

  const parts: string[] = []
  let totalLen = 0
  for (const [key, val] of entries) {
    let valStr: string
    if (typeof val === 'string') {
      valStr = val.length > 60 ? val.slice(0, 57) + '...' : val
    } else if (val === undefined || val === null) {
      continue
    } else {
      valStr = JSON.stringify(val)
      if (valStr.length > 60) valStr = valStr.slice(0, 57) + '...'
    }
    const part = `${key}=${valStr}`
    if (totalLen + part.length > 120) break
    parts.push(part)
    totalLen += part.length
  }
  return parts.join(' ')
}
