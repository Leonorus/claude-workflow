---
name: workflow-script-contract
description: "Strict contract for scripts, automation glue, hooks, cron, LaunchAgents, and local services."
---

# Script workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Script`. This is a compact contract, not a prose tutorial.

## First move

Define input/output, exit codes, idempotency, and side effects.

## Context required

Inspect runtime/schedule conventions, service wrappers, state/log paths, and config surfaces before editing.

## Forbidden early actions

- Do not install/reload persistent jobs before syntax checks and safe smoke/dry-run.
- Do not background daemons outside the managed service/process pattern.
- Do not mutate live config without source/mirror sync plan.

## Verification required

- Run syntax checks for edited scripts/modules.
- Run safe smoke test.
- For cron/launchd/hooks/MCP, verify plist/hook/config/service health and logs.
- For forced scheduled-task runs, verify durable side effects such as state files, locks absent, generated reports, commits or remote HEADs when applicable before trusting a wrapper process exit code; a post-task shell/session cleanup failure can produce a non-zero wrapper exit after the scheduled job itself succeeded.

## Finish condition

State script/service behavior, side effects, sync state, verification evidence, and remaining restart/fresh-session caveats.

## When to escalate bucket

- Script touches prod/remote state/secrets/network or destructive operations: Heavy Ops.
- Bug/root-cause uncertainty dominates: Debug.

## When to use subagents

For non-trivial scripts, use one read-only reviewer for idempotency/runtime/verification; avoid parallel edits to same file.
