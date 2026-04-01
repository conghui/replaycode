#!/usr/bin/env bash
# t17_repl_render.sh — Tier 5: interactive REPL renders UI via PTY
source "$(dirname "$0")/../helpers.sh"
TIER=5; SLOW=true; setup

REPL_OUTPUT="$(timeout 10 script -q /dev/null bash -c "echo '' | $CLI 2>&1" 2>/dev/null || true)"
REPL_STRIPPED="$(echo "$REPL_OUTPUT" | cat -v | tr -d '\r')"

run_test "REPL renders UI" "Claude" "$REPL_STRIPPED"

teardown
