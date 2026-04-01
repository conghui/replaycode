#!/usr/bin/env bash
# t05_json_output.sh — Tier 2: --output-format json produces valid JSON result
source "$(dirname "$0")/../helpers.sh"
TIER=2; SLOW=false; setup

run_test "JSON output" '"type":"result"' \
  "$($CLI -p 'Say ok' --output-format json 2>&1)"

teardown
