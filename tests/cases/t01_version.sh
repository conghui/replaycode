#!/usr/bin/env bash
# t01_version.sh — Tier 1: --version returns correct version string
source "$(dirname "$0")/../helpers.sh"
TIER=1; SLOW=false; setup

run_test "--version" "2.1.88 (Claude Code)" "$($CLI --version 2>&1)"

teardown
