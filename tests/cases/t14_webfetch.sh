#!/usr/bin/env bash
# t14_webfetch.sh — Tier 3: WebFetch tool fetches HTTP URLs
source "$(dirname "$0")/../helpers.sh"
TIER=3; SLOW=false; setup

run_test "WebFetch tool" "httpbin" \
  "$($CLI -p 'Fetch https://httpbin.org/get and reply with just the url field value' --dangerously-skip-permissions 2>&1)"

teardown
