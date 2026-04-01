# ReplayCode Test Suite

End-to-end verification tests for ReplayCode. Each test case is a standalone shell script in `cases/` that validates one specific capability.

## Quick Start

```bash
# Run all tests (fast mode, ~2 min)
bash tests/run.sh --quick

# Run all tests (full mode, ~5 min, includes session/MCP/agent tests)
bash tests/run.sh

# Run a single test case
bash tests/cases/t01_version.sh

# Run one tier only
bash tests/run.sh --tier 3
```

## Test Structure

```
tests/
├── run.sh               # Test runner — discovers and runs all cases
├── helpers.sh            # Shared test utilities (run_test, skip_test, etc.)
├── README.md             # This file
└── cases/
    ├── t01_version.sh        # Tier 1: --version
    ├── t02_help.sh           # Tier 1: --help
    ├── t03_help_flags.sh     # Tier 1: --help lists key flags
    ├── t04_basic_prompt.sh   # Tier 2: basic API call
    ├── t05_json_output.sh    # Tier 2: --output-format json
    ├── t06_system_prompt.sh  # Tier 2: --system-prompt
    ├── t07_stdin_handling.sh # Tier 2: empty stdin
    ├── t08_bash_tool.sh      # Tier 3: Bash tool
    ├── t09_filewrite.sh      # Tier 3: FileWrite tool
    ├── t10_fileread.sh       # Tier 3: FileRead tool
    ├── t11_fileedit.sh       # Tier 3: FileEdit tool
    ├── t12_grep.sh           # Tier 3: Grep tool
    ├── t13_glob.sh           # Tier 3: Glob tool
    ├── t14_webfetch.sh       # Tier 3: WebFetch tool
    ├── t15_multi_tool.sh     # Tier 3: multi-tool single turn
    ├── t16_session_persist.sh  # Tier 4: session create + continue + resume
    ├── t17_repl_render.sh    # Tier 5: interactive REPL renders
    ├── t18_mcp_settings.sh   # Tier 6: MCP from project settings.json
    ├── t19_cost_tracking.sh  # Tier 7: cost/token tracking in JSON
    ├── t20_long_output.sh    # Tier 7: long output stability
    ├── t21_agent_tool.sh     # Tier 7: Agent sub-agent spawning
    └── t22_output_parity.sh  # Comparison: ReplayCode vs claude CLI
```

## Writing a New Test

Each test case is a bash script that sources `helpers.sh` and calls `run_test`:

```bash
#!/usr/bin/env bash
# t99_my_test.sh — Tier N: description of what this tests
source "$(dirname "$0")/../helpers.sh"
TIER=3        # tier number (1-7), used by --tier filter
SLOW=false    # set to true if this test is slow (skipped in --quick mode)

setup  # initializes CLI path, temp dir, etc.

# Your test logic
RESULT="$($CLI -p 'some prompt' --dangerously-skip-permissions 2>&1)"
run_test "My test name" "expected_substring" "$RESULT"

teardown  # cleanup
```

### Conventions

- **Filename**: `tNN_short_name.sh` where NN is a sequence number
- **TIER**: integer 1-7, determines grouping and --tier filter
- **SLOW**: `true` for tests that take >10s (session resume, MCP, agent). Skipped in `--quick`
- **run_test**: `run_test "name" "expected_substring" "actual_output"` — case-insensitive grep
- **Temp files**: use `$TMPDIR` (auto-cleaned). Don't write to the project directory
- **Permissions**: use `--dangerously-skip-permissions` for tool tests
- **Timeouts**: wrap slow commands in `timeout N` to prevent hangs

## Tiers

| Tier | Category | API needed | Speed |
|------|----------|-----------|-------|
| 1 | CLI Basics | No | Fast |
| 2 | Single-turn API | Yes | Fast |
| 3 | Tool Execution | Yes | Fast |
| 4 | Session Persistence | Yes | Slow |
| 5 | Interactive REPL | Yes | Slow |
| 6 | MCP Integration | Yes | Slow |
| 7 | Advanced Features | Yes | Mixed |

## Environment

- `ANTHROPIC_API_KEY` or OAuth credentials required for Tier 2+
- `claude` CLI must be installed for the comparison test (t22)
- `npx` must be available for MCP tests (t18)
