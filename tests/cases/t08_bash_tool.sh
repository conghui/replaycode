#!/usr/bin/env bash
# t08_bash_tool.sh — Tier 3: Bash tool executes shell commands
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

run_test "Bash tool" "BASH_OK" \
  "$($CLI -p 'Run this shell command and show its output: echo BASH_OK' --dangerously-skip-permissions 2>&1)"

teardown
