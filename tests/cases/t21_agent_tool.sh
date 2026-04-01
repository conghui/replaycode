#!/usr/bin/env bash
# t21_agent_tool.sh — Tier 7: Agent tool spawns a sub-agent and returns result
source "$(dirname "$0")/../helpers.sh"
TIER=7; SLOW=true; setup

AGENT_RESULT="$(timeout 60 $CLI -p 'Use the Agent tool to ask a sub-agent: what is the capital of France? Report its answer.' --dangerously-skip-permissions 2>&1 || echo 'TIMEOUT')"
run_test "Agent tool (sub-agent)" "Paris" "$AGENT_RESULT"

teardown
