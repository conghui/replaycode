#!/usr/bin/env bash
# t18_mcp_settings.sh — Tier 6: MCP servers load from project .claude/settings.json
source "$(dirname "$0")/../helpers.sh"
TIER=6; SLOW=true; setup

MCP_DIR="$TMPDIR/mcp-settings-test"
mkdir -p "$MCP_DIR/.claude"
echo "MCP_SETTINGS_OK" > "$MCP_DIR/mcp-test-file.txt"

cat > "$MCP_DIR/.claude/settings.json" << EOF
{
  "mcpServers": {
    "verify-fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "$MCP_DIR"]
    }
  }
}
EOF

MCP_RESULT="$(cd "$MCP_DIR" && timeout 30 $CLI -p "Use the verify-fs MCP read_file tool to read $MCP_DIR/mcp-test-file.txt" --dangerously-skip-permissions 2>&1 || echo 'TIMEOUT')"
run_test "MCP from project settings.json" "MCP_SETTINGS_OK" "$MCP_RESULT"

teardown
