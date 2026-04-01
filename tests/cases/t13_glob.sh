#!/usr/bin/env bash
# t13_glob.sh — Tier 3: Glob tool finds files by pattern
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

run_test "Glob tool" "build.mjs" \
  "$($CLI -p 'Use glob to find all .mjs files in scripts/ directory, list them' --dangerously-skip-permissions 2>&1)"

teardown
