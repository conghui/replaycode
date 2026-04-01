#!/usr/bin/env bash
# t19_cost_tracking.sh — Tier 7: JSON output includes cost/turn metadata
source "$(dirname "$0")/../helpers.sh"
TIER=7; SLOW=false; setup

COST_JSON="$($CLI -p 'Say hi' --output-format json 2>/dev/null || echo '{}')"
run_test "Cost tracking in JSON" "num_turns" "$COST_JSON"

teardown
