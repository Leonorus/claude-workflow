#!/usr/bin/env sh
# SessionStart hook: trigger-only Obsidian reminder.
# Do not read or inject a vault index here; Workflow/Obsidian MCP does targeted
# discovery after the task bucket is known.
cat <<'EOF'
<system-reminder>
Obsidian: hook is trigger-only; do not infer or cite note candidates from it. For Ops/Infra/Debug/architecture/reusable research, use Workflow MCP start_task/discover_context or Obsidian MCP, then read matching notes before claims. Vault: ~/Obsidian/Work.
</system-reminder>
EOF
