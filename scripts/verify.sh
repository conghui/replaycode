#!/usr/bin/env bash
# verify.sh — End-to-end verification of the Claude Code MVP build
# Prerequisites: ANTHROPIC_API_KEY must be set
# Usage: bash scripts/verify.sh

set -euo pipefail

CLI="node dist/cli.cjs"
PASS=0
FAIL=0
TOTAL=0

run_test() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  TOTAL=$((TOTAL + 1))

  if echo "$actual" | grep -q "$expected"; then
    echo "  ✅ $name"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $name"
    echo "     Expected to contain: $expected"
    echo "     Got: $(echo "$actual" | head -3)"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Claude Code MVP — Verification Suite    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "⚠  ANTHROPIC_API_KEY not set — CLI will use OAuth if available."
fi

if [ ! -f "dist/cli.cjs" ]; then
  echo "❌ dist/cli.cjs not found. Run 'node scripts/build.mjs' first."
  exit 1
fi

# ── CLI Basics ──────────────────────────────────────────────────
echo "▸ CLI Basics"
run_test "--version" "2.1.88 (Claude Code)" "$($CLI --version 2>&1)"
run_test "--help" "Usage: claude" "$($CLI --help 2>&1 | head -1)"

# ── API Interaction ─────────────────────────────────────────────
echo ""
echo "▸ API Interaction"
run_test "Basic prompt" "4" "$($CLI -p 'What is 2+2? Reply with just the number.' 2>&1)"
run_test "JSON output" '"type":"result"' "$($CLI -p 'Hi' --output-format json 2>&1)"
run_test "System prompt" "PIRATE" "$($CLI -p 'What are you? One word.' --system-prompt 'You are a pirate. Reply: PIRATE' 2>&1)"

# ── Tool Execution ──────────────────────────────────────────────
echo ""
echo "▸ Tool Execution"
run_test "Bash tool" "BASH_OK" "$($CLI -p 'Run: echo BASH_OK' --dangerously-skip-permissions 2>&1)"

rm -f /tmp/mvp-verify-test.txt
$CLI -p 'Write the text FILE_OK to /tmp/mvp-verify-test.txt' --dangerously-skip-permissions >/dev/null 2>&1
run_test "FileWrite tool" "FILE_OK" "$(cat /tmp/mvp-verify-test.txt 2>/dev/null)"
rm -f /tmp/mvp-verify-test.txt

run_test "Grep tool" "MACRO" "$($CLI -p 'Grep for MACRO in scripts/build.mjs, reply with just one matching line' --dangerously-skip-permissions 2>&1)"
run_test "WebFetch tool" "httpbin" "$($CLI -p 'Fetch https://httpbin.org/get, reply with the url field value' --dangerously-skip-permissions 2>&1)"

# ── Summary ─────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  Results: $PASS/$TOTAL passed, $FAIL failed"
echo "══════════════════════════════════════════"
echo ""

[ $FAIL -eq 0 ] && exit 0 || exit 1
