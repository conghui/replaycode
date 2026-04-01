#!/usr/bin/env bash
# verify.sh — Legacy wrapper. Delegates to tests/run.sh
# Usage: bash scripts/verify.sh [--quick]
exec bash "$(dirname "$0")/../tests/run.sh" "$@"
