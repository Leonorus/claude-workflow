---
name: workflow-light-ops-contract
description: "Strict contract for small low-risk config/CI/ops edits."
---

# Light Ops workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Light Ops`. This is a compact contract, not a prose tutorial.

## First move

Inspect nearby convention before editing.

## Context required

Read the affected config and adjacent examples; Obsidian is not required unless design/prod/secrets/network risk appears.

## Forbidden early actions

- Do not widen scope beyond the small config/convention change without reclassifying.
- Do not treat the word prod alone as Heavy Ops when the task is CI-only/list-only and excludes secrets/runtime config.
- Do not apply remote changes.

## Verification required

- Run targeted lint/fmt/schema/render/check for the affected file type.
- Review git diff/status for unintended edits.
- For CI image changes, verify the image repository and tag exist before editing or finalizing; do not invent plausible registry paths from naming conventions.

## Finish condition

Summarize exact files changed, targeted verification, and whether the task stayed Light Ops.

## When to escalate bucket

- Diff grows beyond roughly 50 lines or multiple files.
- Touches prod runtime state, secrets values, network/security, RBAC/IAM, Terraform apply, Helm values applied to clusters, or rollback-sensitive paths.
- A deeper design issue appears.

## When to use subagents

Usually direct. Optionally use one read-only reviewer/validator when cheap.
