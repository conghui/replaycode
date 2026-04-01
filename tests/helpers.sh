#!/usr/bin/env bash
# helpers.sh — Shared utilities for ReplayCode test cases

# Resolve project root (works from any cwd)
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
CLI="node $PROJECT_ROOT/dist/cli.cjs"

# Test counters (per-file)
_PASS=0
_FAIL=0
_SKIP=0
_TOTAL=0

# Temp directory for this test (auto-cleaned)
TMPDIR="/tmp/replaycode-test-$$"

setup() {
  mkdir -p "$TMPDIR"

  if [ ! -f "$PROJECT_ROOT/dist/cli.cjs" ]; then
    echo "❌ dist/cli.cjs not found. Run 'npm run build' first."
    exit 1
  fi
}

teardown() {
  rm -rf "$TMPDIR" 2>/dev/null || true

  # Print per-file summary when running standalone
  if [ "${_STANDALONE:-false}" = "true" ]; then
    if [ $_FAIL -eq 0 ] && [ $_SKIP -eq 0 ]; then
      echo "  ── $_PASS/$_TOTAL passed"
    elif [ $_FAIL -eq 0 ]; then
      echo "  ── $_PASS passed, $_SKIP skipped (of $_TOTAL)"
    else
      echo "  ── $_PASS passed, $_FAIL FAILED, $_SKIP skipped (of $_TOTAL)"
    fi
  fi

  # Exit with failure if any test failed
  [ $_FAIL -eq 0 ]
}

run_test() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  _TOTAL=$((_TOTAL + 1))

  if echo "$actual" | grep -qi "$expected"; then
    echo "  ✅ $name"
    _PASS=$((_PASS + 1))
  else
    echo "  ❌ $name"
    echo "     Expected to contain: $expected"
    echo "     Got: $(echo "$actual" | head -3)"
    _FAIL=$((_FAIL + 1))
  fi
}

skip_test() {
  local name="$1"
  _TOTAL=$((_TOTAL + 1))
  _SKIP=$((_SKIP + 1))
  echo "  ⏭  $name (skipped)"
}

# Detect if running standalone (not from run.sh)
if [ -z "${RUNNER_PID:-}" ]; then
  _STANDALONE=true
fi
