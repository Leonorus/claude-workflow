#!/usr/bin/env sh
# install.sh — one-time setup for this claude-workflow fork.
#
# Merges MCP server definitions from ./mcp.json into ~/.claude.json, which is
# where Claude Code actually reads user-scope MCP servers from (not ~/.claude/mcp.json).
# Safe to re-run: backs up ~/.claude.json first, merges idempotently.

set -eu

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_JSON="$HOME/.claude.json"
MCP_JSON="$REPO_DIR/mcp.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (brew install jq)" >&2
  exit 1
fi

if [ ! -f "$MCP_JSON" ]; then
  echo "error: $MCP_JSON not found" >&2
  exit 1
fi

if [ ! -f "$CLAUDE_JSON" ]; then
  echo '{}' > "$CLAUDE_JSON"
fi

backup="$CLAUDE_JSON.bak.$(date +%Y%m%d-%H%M%S)"
cp "$CLAUDE_JSON" "$backup"
echo "Backed up $CLAUDE_JSON → $backup"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq --slurpfile src "$MCP_JSON" '
  .mcpServers = ((.mcpServers // {}) + $src[0].mcpServers)
' "$CLAUDE_JSON" > "$tmp"
mv "$tmp" "$CLAUDE_JSON"
trap - EXIT

echo "Merged servers from mcp.json:"
jq -r '.mcpServers | keys[]' "$CLAUDE_JSON" | sed 's/^/  - /'
echo ""
echo "Restart Claude Code to pick up the new servers."
