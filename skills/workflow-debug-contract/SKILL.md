---
name: workflow-debug-contract
description: "Strict contract for failures, regressions, stack traces, timeouts, or unexpected behavior."
---

# Debug workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Debug`. This is a compact contract, not a prose tutorial.

## First move

Reproduce or observe the exact failure before fixing.

## Context required

Read logs/tests/error output and relevant prior Obsidian notes via `mcp__docker_gateway__obsidian_*` when available before relying on previous incidents.

## Forbidden early actions

- Do not patch before observing the failure and naming falsifiable hypotheses.
- Do not stop at symptom fixes unless user explicitly accepts.
- Do not claim fixed without verifying the exact failure path.

## Verification required

- Run the failing test/smoke/repro again and show it passes or state blocker.
- Add/regress a test when practical.
- Review no unrelated changes.

## Finish condition

State root cause, fix, exact verification, and write/offer project note for concrete findings/fixes via `mcp__docker_gateway__obsidian_*` write tools unless duplicate/trivial. If the finding changes commands, architecture, safety rules, or conventions, check repo `AGENTS.md`; rewrite stale or missing guidance directly as part of the task finisher with normal diff review and verification.

## When to escalate bucket

- Failure crosses prod/secrets/network/data migration boundary: Heavy Ops plus Debug.
- Unclear architecture/performance tradeoff dominates: use reasoning guard.

## When to use subagents

Use independent read-only investigators for unclear bugs: repro/logs versus code/config path.
