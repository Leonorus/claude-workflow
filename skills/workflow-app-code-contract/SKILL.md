---
name: workflow-app-code-contract
description: "Strict contract for application behavior, module, API, frontend/backend, or test changes."
---

# App Code workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `App Code`. This is a compact contract, not a prose tutorial.

## First move

Define success criteria and inspect existing test shape before implementation.

## Context required

Read project conventions, relevant files, and tests. Use TDD/review skills when behavior changes or tests already exist.

## Forbidden early actions

- Do not broad-refactor before success criteria are clear.
- Do not add speculative abstractions or flags.
- Do not claim behavior success without targeted tests or a clear blocker.

## Verification required

- Run smallest relevant test first, then broader tests/lint/typecheck/build only as needed.
- Review diff for scope creep.

## Finish condition

State behavior changed, files changed, tests/checks run, docs/API updates or why none.

## When to escalate bucket

- Cross-service, migration, security, performance, or production rollout risk appears.
- Root cause is unclear failure: switch to Debug.

## When to use subagents

Use implementer/reviewer subagents only for independent modules or review streams; avoid competing edits to the same files.
