#!/usr/bin/env bash
# t07_stdin_handling.sh — Tier 2: handles empty stdin gracefully
source "$(dirname "$0")/../helpers.sh"
TIER=2; SLOW=false; setup

run_test "Empty stdin handling" "ok" \
  "$(echo '' | $CLI -p 'Say ok' 2>&1)"

teardown
