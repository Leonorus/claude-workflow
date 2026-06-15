---
name: workflow-repo-maintenance-contract
description: "Strict contract for dependencies, CI cleanup, docs cleanup, release metadata, and repository convention maintenance."
---

# Repo-maintenance workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Repo-maintenance`. This is a compact contract, not a prose tutorial.

## First move

Check git status/diff and preserve unrelated user changes.

## Context required

Inspect affected areas: CI, dependencies, docs, documentation translation/localization, tests, release metadata, config conventions, and project instructions.

## Forbidden early actions

- Do not stage or rewrite unrelated changes.
- Do not create commits/branches without the required Jira/project convention unless explicitly bypassed.
- Do not fix unrelated issues inline.

## Verification required

- For branch-history maintenance such as rebase, cherry-pick, or force-with-lease, inspect `git status --branch`, graph/todo state, and upstream ancestry before continuing after conflicts. If conflicts come from replaying commits that are already integrated upstream, prefer aborting and rebasing only unique commits with `git rebase --onto <base> <last-duplicate> <branch>` over resolving duplicate conflicts by hand.
- Run affected checks by surface: CI syntax, dependency tests, docs references, Markdown/code-fence sanity for docs translations, release metadata checks, diff check.
- After a force-with-lease push, fetch the remote branch and verify remote HEAD equals local HEAD and the target base is an ancestor.
- Report unrelated findings separately.

## Finish condition

State changed surfaces, verification, unrelated changes preserved, docs/notes/skill updates or why none.

## When to escalate bucket

- Workflow policy/hooks/MCP/config surfaces changed: reasoning guard and surface validation.
- Production/runtime config or secrets appear: Heavy Ops.

## When to use subagents

Split independent read-only inspectors for CI/deps/docs/tests/release metadata when useful.
