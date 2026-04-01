#!/usr/bin/env bash
# t15_multi_tool.sh — Tier 3: multiple tools used in a single turn
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

run_test "Multi-tool turn" "SUCCESS" \
  "$($CLI -p "Do these steps: 1) run 'echo step1' in bash, 2) write 'step2' to $TMPDIR/multi.txt, 3) read that file back. If all worked, say SUCCESS." --dangerously-skip-permissions 2>&1)"

teardown
