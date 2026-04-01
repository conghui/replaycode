#!/usr/bin/env bash
# t11_fileedit.sh — Tier 3: FileEdit tool performs string replacement
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

echo "old_value = 1" > "$TMPDIR/edit-test.txt"
$CLI -p "Edit $TMPDIR/edit-test.txt: replace 'old_value' with 'new_value'" --dangerously-skip-permissions >/dev/null 2>&1
run_test "FileEdit tool" "new_value" "$(cat "$TMPDIR/edit-test.txt" 2>/dev/null || echo 'EDIT_FAILED')"

teardown
