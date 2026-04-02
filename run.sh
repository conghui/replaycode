#!/bin/bash
# ReplayCode 启动脚本 - 使用独立配置目录，避免和原有 Claude Code 冲突

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 独立的配置/数据目录
export CLAUDE_CONFIG_DIR="$HOME/.replaycode"
export CLAUDE_DATA_DIR="$HOME/.replaycode/data"
mkdir -p "$CLAUDE_CONFIG_DIR" "$CLAUDE_DATA_DIR"

# API 配置（可被环境变量覆盖）
: "${ANTHROPIC_API_KEY:=your-api-key-here}"
: "${ANTHROPIC_BASE_URL:=https://api.anthropic.com}"
: "${ANTHROPIC_MODEL:=claude-sonnet-4-20250514}"
export ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_MODEL

# 判断是否使用官方 API
_host="$(echo "$ANTHROPIC_BASE_URL" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d':' -f1)"
if [ "$_host" = "api.anthropic.com" ]; then
    # 官方 API：不加任何禁用参数，恢复正常行为
    unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
    unset CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS
    unset DISABLE_INTERLEAVED_THINKING
    unset DISABLE_PROMPT_CACHING
    unset DISABLE_SANDBOX
else
    # 第三方中转：禁用不兼容的功能
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    export DISABLE_INTERLEAVED_THINKING=1
    export DISABLE_PROMPT_CACHING=1
    export DISABLE_SANDBOX=1
    # 清除代理（直连中转服务器）
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    export no_proxy="*"
fi

# 启动
node "$SCRIPT_DIR/dist/cli.cjs" "$@"
