#!/usr/bin/env sh
# Stop hook: enforce the Workflow MCP finish loop.
# If this session called mcp__workflow__start_task but never
# mcp__workflow__finish_checklist, block the stop once and remind the agent
# to close the loop. stop_hook_active guards against an infinite block loop.
input=$(cat)

# If we already blocked once this turn, let the agent stop.
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$active" = "true" ] && exit 0

tp=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$tp" ] && exit 0
[ -f "$tp" ] || exit 0

if grep -q 'mcp__workflow__start_task' "$tp" 2>/dev/null \
   && ! grep -q 'mcp__workflow__finish_checklist' "$tp" 2>/dev/null; then
  printf '{"decision":"block","reason":"Workflow finish loop not closed: you called start_task but never finish_checklist this session. Call mcp__workflow__finish_checklist(task_id, bucket, ...) to close the loop (state verification + diff review), then stop."}\n'
  exit 0
fi

exit 0
