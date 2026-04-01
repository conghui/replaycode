#!/usr/bin/env bash
# t10_fileread.sh — Tier 3: FileRead tool reads file content correctly
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

echo "READ_OK_CONTENT" > "$TMPDIR/read-test.txt"
run_test "FileRead tool" "READ_OK_CONTENT" \
  "$($CLI -p "Read the file $TMPDIR/read-test.txt and show its content" --dangerously-skip-permissions 2>&1)"

teardown
