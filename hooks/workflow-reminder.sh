#!/usr/bin/env sh
# UserPromptSubmit hook: enforce the Workflow MCP first-move loop on every prompt.
# Mirrors the Codex behaviour: prompt -> classify -> follow bucket contract.
cat <<'EOF'
<system-reminder>
First move on any non-trivia task (software/ops/debug/research/repo-maintenance): call mcp__workflow__start_task(prompt, cwd, repo) BEFORE planning, proposing, or editing. Then: (1) state or override the returned bucket in one line, (2) load the returned skills (codex-workflow + workflow-<bucket>-contract + codex-knowledge), (3) execute that contract end to end — first move, required context, delegation, verification, finish. Read prior notes via Workflow/Obsidian MCP before any Obsidian claim. Close non-trivia with mcp__workflow__finish_checklist(task_id). If Workflow MCP is unavailable or obviously wrong, fall back to the codex-workflow skill.
</system-reminder>
EOF
