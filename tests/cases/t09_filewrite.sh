#!/usr/bin/env bash
# t09_filewrite.sh — Tier 3: FileWrite tool creates files with correct content
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

WRITE_FILE="$TMPDIR/write-test.txt"
$CLI -p "Write exactly the text FILE_OK to $WRITE_FILE" --dangerously-skip-permissions >/dev/null 2>&1
run_test "FileWrite tool" "FILE_OK" "$(cat "$WRITE_FILE" 2>/dev/null || echo 'FILE_NOT_FOUND')"

teardown
