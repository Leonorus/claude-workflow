---
name: classify-task
description: Fallback workflow classifier for Claude Code when Workflow MCP is unavailable or obviously wrong. For substantial software/ops/debug/research/repo-maintenance, prefer Workflow MCP start_task first.
---

# Classify task

Use this skill as the human-readable fallback when Workflow MCP is unavailable,
stale, or clearly wrong. If `mcp__workflow__start_task` is available, call it
instead and follow its returned contract/checklist.

## Start rule

For non-trivia work, state one short visible sentence:

`Bucket: <bucket> — <why>; applying <matching workflow weight>.`

Skip only for casual chat, pure trivia, or clear follow-ups to an already
classified task in this conversation.

## Buckets

| Bucket | Signals | Flow |
|---|---|---|
| Trivia | Typo, one-line obvious doc/config fix, mechanical rename | Just do it. No plan, no note, no subagent. |
| Light Ops | Single-file Ansible/Terraform/k8s/CI/Docker, small diff, no direct prod/secret/network/apply boundary, no new role/module/stack | Inspect nearby convention -> edit surgically -> run targeted lint/fmt/check -> summarize. |
| Heavy Ops | Multi-file ops, actual prod boundary, secrets/network/security, new role/module/stack, architectural shift, repeated pattern | Name blast radius/assumptions/rollback or dry-run path -> consult Workflow/Obsidian context -> plan -> implement -> lint/validate/render/dry-run/smoke -> docs/note. |
| App Code | Behavior/API/module change, tests present, multiple packages/modules | Define success and existing test shape -> add/run targeted failing test where practical -> implement -> targeted tests -> docs if behavior changed. |
| Script | Single-file glue/automation/hook/cron/LaunchAgent/local service, no app harness | Define input/output/exit codes/idempotency/side effects -> inspect runtime conventions -> minimal edit -> syntax check + safe smoke test. |
| Debug | Bug report, failing test, stack trace, unexpected behavior | Reproduce/observe exact failure -> name falsifiable hypotheses -> inspect/instrument -> fix cause -> verify exact failure is gone. |
| Research | How does X work, compare options, repo exploration, no code change | State question/evidence bar -> read sources/notes -> report facts, assumptions, recommendation, confidence, risks, next checks. |
| Repo-maintenance | Dependency/CI/docs/tests/release/config hygiene | Check status/diff -> inspect affected convention -> edit surgically -> run affected validation -> update docs/notes if conventions changed. |
| Ambiguous | Multiple buckets fit or scope changes tool choice | Ask one concise clarifying question, or proceed only with an explicit low-risk assumption. |

Escalate Light Ops to Heavy Ops if the diff grows beyond roughly 50 lines,
spreads across files, touches actual prod/secrets/network/runtime state, reveals
a deeper design issue, or repeats across multiple repos. Do not classify a task
as Heavy Ops from the word "prod" alone when the change is only CI/list/matrix
wiring with variable names/placeholders and no secret values, runtime config,
RBAC, network policy, Terraform/Ansible state, Helm values, or direct deploy.

## Subagents

Use Claude Code subagents proportionally:

- Trivia: never.
- Light Ops: usually direct; optionally one cheap read-only reviewer/validator.
- Script: one read-only reviewer for non-trivial hooks/cron/local services.
- Research: 2-3 independent researchers when scope permits.
- App Code: use implementer/reviewer subagents only for independent modules.
- Debug: use an independent investigator for unclear root cause.
- Heavy Ops: use read-only discovery/risk/validation reviewers; keep destructive
  applies and final decisions in main.
- Repo-maintenance: split independent areas (CI, deps, docs, tests) when useful.
- Ambiguous: clarify first.

Parent must verify subagent claims before reporting success.

## Obsidian / knowledge

For Ops/Infra, Debug, architecture choices, and reusable research, use Workflow
MCP `start_task`/`discover_context` or Obsidian MCP search before making
knowledge-base claims. Candidate paths or hook reminders are routing metadata,
not evidence; cite only notes actually read.

End-of-task note rule:

- Heavy Ops and Debug with a shipped fix or concrete findings: write a raw note
  unless duplicate or trivial.
- Other non-trivia: ask "Take a note for this?" with a one-line summary and
  target path.

## Finish

Before final response:

- Review git status/diff for unintended edits when in a repo.
- State exact verification commands/results, or exact blocker.
- Update affected docs when workflow, commands, architecture, or conventions
  changed; otherwise say none were affected.
- Run Workflow MCP `finish_checklist` when available for non-trivia work.
