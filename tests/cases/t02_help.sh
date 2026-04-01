#!/usr/bin/env bash
# t02_help.sh — Tier 1: --help shows usage information
source "$(dirname "$0")/../helpers.sh"
TIER=1; SLOW=false; setup

run_test "--help" "Usage: claude" "$($CLI --help 2>&1 | head -1)"

teardown
