---
name: classify-task
description: Use at the very start of any user request, before invoking other skills or writing any code. Classifies the request into one of the workflow buckets (trivia, ops/infra, go-python-app, go-python-script, debug, research, ambiguous) and applies the matching weight. Asks the user if classification is uncertain.
---

# Classify task

First move on any request. Decides how much process to apply. Without this, you default to "do the heavy workflow on everything" or "do nothing structured" — both wrong.

## The buckets

| Bucket | Signals | Weight applied |
|---|---|---|
| **Trivia** | typo, one-char rename, single-line config tweak, obvious doc fix | Just do it. No brainstorm, no plan, no arch review, no doc update. |
| **Ops / Infra** | Ansible playbook/role, Terraform module, shell script, k8s manifest, CI workflow, Dockerfile | Short plan if >1 file. No TDD. Dry-run / `--check` / `terraform plan` before apply. Arch review. Post-change doc update. |
| **Go / Python app code** | project has `go.mod` or `pyproject.toml`, has `tests/` or `_test.go`, multiple modules/packages | Brainstorm → writing-plans → **TDD** (red-green-refactor) → requesting-code-review → architecture-review → verification-before-completion → update-project-docs. |
| **Go / Python script** | single file, <~100 lines, glue/automation, no tests dir, run-once or cron | Short plan if non-trivial. No TDD — manual smoke test. Arch review. Post-change doc update. |
| **Debug** | bug report, test failure, stack trace provided, "why is X broken", unexpected behavior description | systematic-debugging: hypothesis → minimal repro → instrument → targeted fix → verify. No speculative fixes. If a fix ships, then code review + arch review + verify + doc update. Investigation-only: write findings to Obsidian, stop. |
| **Research / Exploration** | "how does X work", "what's in this repo", "compare A vs B" — no bug, no code change expected | Read, investigate, report. No workflow weight. Write findings to `~/Obsidian/Work/Knowledge/<topic>.md` or `Projects/<repo>/...` if repo-specific. |
| **Ambiguous** | two or more buckets fit, or no bucket clearly fits, or the scope is unclear | **Ask the user** which bucket + rough scope before proceeding. Do not guess. |

## Procedure

1. Read the user's message end-to-end, including any pasted stack traces, file paths, or referenced tickets.
2. Pick the bucket. If none fits cleanly, pick **Ambiguous** and ask.
3. State the classification out loud in one short sentence ("Treating this as debug — running systematic-debugging next").
4. Apply the weight. Invoke the skills named in the bucket row, in order.
5. **Do not** skip the taxonomy step "because it's small" — say "trivia" out loud and then do it.

## Cross-cutting rules (all buckets except trivia and pure research)

- After meaningful code/config change, update `AGENTS.md` + affected docs via `update-project-docs` skill.
- Always-on meta-principles: think-before-coding, simplicity-first, surgical-changes, goal-driven-execution.
- Plans/notes → Obsidian (`mcp__obsidian__*` tools), not in-repo.

## Anti-patterns
- Classifying silently and moving on — the classification must be visible to the user.
- Applying full Go/Python-app weight to a 20-line script just because it's Python.
- Applying trivia weight to something that touches production config.
- Skipping the "ambiguous → ask" step and guessing.
