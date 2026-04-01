#!/usr/bin/env bash
# t12_grep.sh — Tier 3: Grep tool searches file content
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

run_test "Grep tool" "MACRO" \
  "$($CLI -p 'Grep for the word MACRO in scripts/build.mjs, reply with just one matching line' --dangerously-skip-permissions 2>&1)"

teardown
