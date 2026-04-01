#!/usr/bin/env bash
# t20_long_output.sh — Tier 7: long output doesn't crash or truncate
source "$(dirname "$0")/../helpers.sh"
TIER=7; SLOW=false; setup

run_test "Long output stability" "done" \
  "$($CLI -p 'List numbers 1 to 50 one per line, then say done.' --dangerously-skip-permissions 2>&1 | tail -5)"

teardown
