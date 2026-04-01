#!/usr/bin/env bash
# t03_help_flags.sh — Tier 1: --help lists key CLI flags
source "$(dirname "$0")/../helpers.sh"
TIER=1; SLOW=false; setup

run_test "--help lists flags" "dangerously-skip-permissions" "$($CLI --help 2>&1)"

teardown
