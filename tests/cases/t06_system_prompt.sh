#!/usr/bin/env bash
# t06_system_prompt.sh — Tier 2: --system-prompt overrides behavior
source "$(dirname "$0")/../helpers.sh"
TIER=2; SLOW=false; setup

run_test "System prompt" "PIRATE" \
  "$($CLI -p 'What are you? One word.' --system-prompt 'You are a pirate. Reply only: PIRATE' 2>&1)"

teardown
