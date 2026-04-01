#!/usr/bin/env bash
# t22_output_parity.sh — Comparison: ReplayCode and claude CLI produce same answer
source "$(dirname "$0")/../helpers.sh"
TIER=7; SLOW=true; setup

if ! command -v claude &>/dev/null; then
  skip_test "Output parity (claude CLI not found)"
  teardown
  exit 0
fi

REPLAY_VERSION="$($CLI --version 2>&1)"
CLAUDE_VERSION="$(claude --version 2>&1)"
echo "  📌 ReplayCode: $REPLAY_VERSION"
echo "  📌 Claude CLI: $CLAUDE_VERSION"

PROMPT="What is the square root of 144? Reply with just the number."
REPLAY_ANS="$($CLI -p "$PROMPT" 2>&1)"
CLAUDE_ANS="$(timeout 15 claude -p "$PROMPT" 2>&1 || echo 'CLAUDE_TIMEOUT')"

REPLAY_HAS="$(echo "$REPLAY_ANS" | grep -c '12' || true)"
CLAUDE_HAS="$(echo "$CLAUDE_ANS" | grep -c '12' || true)"

if [ "$REPLAY_HAS" -gt 0 ] && [ "$CLAUDE_HAS" -gt 0 ]; then
  run_test "Output parity" "12" "12"
else
  run_test "Output parity" "both_12" "replay=${REPLAY_ANS} claude=${CLAUDE_ANS}"
fi

teardown
