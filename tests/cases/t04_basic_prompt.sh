#!/usr/bin/env bash
# t04_basic_prompt.sh — Tier 2: basic API call returns correct answer
source "$(dirname "$0")/../helpers.sh"
TIER=2; SLOW=false; setup

run_test "Basic prompt" "4" \
  "$($CLI -p 'What is 2+2? Reply with just the number.' 2>&1)"

teardown
