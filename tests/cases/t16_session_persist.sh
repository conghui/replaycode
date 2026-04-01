#!/usr/bin/env bash
# t16_session_persist.sh — Tier 4: session creation, --continue, and --resume
source "$(dirname "$0")/../helpers.sh"
TIER=4; SLOW=true; setup

SESSION_DIR="$TMPDIR/session-test"
mkdir -p "$SESSION_DIR"

# Session 1: remember a code
(cd "$SESSION_DIR" && timeout 30 $CLI -p "Remember this code: KIWI99. Just confirm you got it." --dangerously-skip-permissions >/dev/null 2>&1) || true

# Check session file was created
SESSION_DIR_REAL="$(cd "$SESSION_DIR" && pwd -P | tr '/' '-' | sed 's/^-//')"
SESSION_PROJ="$(find ~/.claude/projects/ -name "*.jsonl" -newer "$TMPDIR" 2>/dev/null | grep "$SESSION_DIR_REAL" | head -1 || echo '')"
if [ -z "$SESSION_PROJ" ]; then
  SESSION_PROJ="$(find ~/.claude/projects/ -name "*.jsonl" -newer "$TMPDIR" 2>/dev/null | head -1 || echo '')"
fi
run_test "Session file created" ".jsonl" "${SESSION_PROJ:-NO_SESSION}"

# --continue and recall
if [ -n "$SESSION_PROJ" ]; then
  CONTINUE_RESULT="$(cd "$SESSION_DIR" && timeout 30 $CLI --continue -p "What was the code I told you? Reply with just the code." 2>&1 || echo 'TIMEOUT')"
  run_test "Session create + continue" "KIWI99" "$CONTINUE_RESULT"

  # --resume with session ID
  SID="$(basename "$SESSION_PROJ" .jsonl)"
  RESUME_RESULT="$(cd "$SESSION_DIR" && timeout 30 $CLI --resume "$SID" -p "What code did I share? Just the code." 2>&1 || echo 'TIMEOUT')"
  run_test "--resume by session ID" "KIWI99" "$RESUME_RESULT"
else
  skip_test "Session create + continue"
  skip_test "--resume by session ID"
fi

teardown
