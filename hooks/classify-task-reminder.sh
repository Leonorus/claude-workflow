#!/usr/bin/env sh
# UserPromptSubmit hook: compact Workflow MCP first-move reminder.
cat <<'EOF'
<system-reminder>
Workflow: for substantial software/ops/debug/research/repo-maintenance, call Workflow MCP start_task(prompt,cwd,repo) first; state/override bucket, load returned skills, follow contract/context/delegation/finish checklist. Use Workflow/Obsidian MCP before Obsidian claims. Finish non-trivia with Workflow MCP finish_checklist. Fallback: classify-task.
</system-reminder>
EOF
