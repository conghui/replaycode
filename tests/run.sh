#!/usr/bin/env bash
# run.sh — Test runner for ReplayCode verification suite
#
# Usage:
#   bash tests/run.sh              # full mode (all tests)
#   bash tests/run.sh --quick      # skip slow tests
#   bash tests/run.sh --tier 3     # run only tier 3 tests
#   bash tests/run.sh --tier 1-3   # run tiers 1 through 3

set -euo pipefail

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
QUICK=false
TIER_FILTER=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) QUICK=true; shift ;;
    --tier)  TIER_FILTER="$2"; shift 2 ;;
    *)       echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Parse tier filter (e.g., "3" or "1-3")
TIER_MIN=1
TIER_MAX=9
if [ -n "$TIER_FILTER" ]; then
  if [[ "$TIER_FILTER" == *-* ]]; then
    TIER_MIN="${TIER_FILTER%-*}"
    TIER_MAX="${TIER_FILTER#*-}"
  else
    TIER_MIN="$TIER_FILTER"
    TIER_MAX="$TIER_FILTER"
  fi
fi

export RUNNER_PID=$$

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  ReplayCode — Verification Suite         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "⚠  ANTHROPIC_API_KEY not set — CLI will use OAuth if available."
fi

if [ ! -f "$PROJECT_ROOT/dist/cli.cjs" ]; then
  echo "❌ dist/cli.cjs not found. Run 'npm run build' first."
  exit 1
fi

PASS=0
FAIL=0
SKIP=0
TOTAL=0
CURRENT_TIER=0

TIER_NAMES=(
  ""
  "Tier 1: CLI Basics"
  "Tier 2: Single-turn API"
  "Tier 3: Tool Execution"
  "Tier 4: Session Persistence"
  "Tier 5: Interactive REPL"
  "Tier 6: MCP Integration"
  "Tier 7: Advanced Features"
)

# Discover and run test cases in order
for test_file in "$TEST_DIR/cases"/t*.sh; do
  [ -f "$test_file" ] || continue

  # Extract TIER and SLOW from the file (macOS-compatible)
  FILE_TIER="$(sed -n 's/^TIER=\([0-9]*\).*/\1/p' "$test_file" | head -1)"
  FILE_SLOW="$(sed -n 's/.*SLOW=\([a-z]*\).*/\1/p' "$test_file" | head -1)"
  FILE_TIER="${FILE_TIER:-0}"
  FILE_SLOW="${FILE_SLOW:-false}"

  # Tier filter
  if [ "$FILE_TIER" -lt "$TIER_MIN" ] || [ "$FILE_TIER" -gt "$TIER_MAX" ]; then
    continue
  fi

  # Print tier header on tier change
  if [ "$FILE_TIER" -ne "$CURRENT_TIER" ]; then
    CURRENT_TIER="$FILE_TIER"
    echo ""
    echo "▸ ${TIER_NAMES[$CURRENT_TIER]:-Tier $CURRENT_TIER}"
  fi

  # Skip slow tests in quick mode
  if $QUICK && [ "$FILE_SLOW" = "true" ]; then
    TEST_NAME="$(basename "$test_file" .sh | sed 's/^t[0-9]*_//' | tr '_' ' ')"
    TOTAL=$((TOTAL + 1))
    SKIP=$((SKIP + 1))
    echo "  ⏭  $TEST_NAME (skipped, use full mode)"
    continue
  fi

  # Run the test and capture its output
  OUTPUT="$(bash "$test_file" 2>&1)" || true

  # Parse results from output
  while IFS= read -r line; do
    case "$line" in
      *✅*) PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1)); echo "$line" ;;
      *❌*) FAIL=$((FAIL + 1)); TOTAL=$((TOTAL + 1)); echo "$line" ;;
      *⏭*)  SKIP=$((SKIP + 1)); TOTAL=$((TOTAL + 1)); echo "$line" ;;
      *Expected*|*Got:*|*📌*) echo "$line" ;;
    esac
  done <<< "$OUTPUT"
done

# Summary
echo ""
echo "══════════════════════════════════════════"
if [ $SKIP -gt 0 ]; then
  echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped (of $TOTAL)"
else
  echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
fi
echo "══════════════════════════════════════════"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
