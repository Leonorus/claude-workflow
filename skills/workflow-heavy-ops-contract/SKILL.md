---
name: workflow-heavy-ops-contract
description: "Strict contract for high-risk ops, production, secrets, network, migration, or rollback-sensitive work."
---

# Heavy Ops workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Heavy Ops`. This is a compact contract, not a prose tutorial.

## First move

Name blast radius, assumptions, rollback/dry-run path, and validation before proposing mutation.

## Context required

Read relevant repo files and directly relevant Obsidian/Organization/Knowledge notes via `mcp__docker_gateway__obsidian_*` when available before relying on prior context. Candidate paths are not evidence until read.

## Forbidden early actions

- Do not apply, delete, rotate, migrate, or mutate remote/prod state before blast radius and rollback/dry-run are explicit.
- Do not inspect or print secret values.
- Do not let subagents perform destructive actions.

## Verification required

- Run lint/render/validate/dry-run/smoke checks appropriate to the stack.
- Verify rollback/undo path or state why unavailable.
- Record command evidence.

## Finish condition

State risk controls, files changed, verification, side effects, rollback status, and write/offer the required project note for concrete findings/fixes via `mcp__docker_gateway__obsidian_*` write tools. If the work changes commands, architecture, safety rules, or conventions, check repo `AGENTS.md`; rewrite stale or missing guidance directly as part of the task finisher with normal diff review and verification.

## When to escalate bucket

- Architecture or migration decision appears: include alternatives and decision rule.
- Actual prod apply/delete/secret operation requested: require explicit scope and confirmation path.

## When to use subagents

Use read-only discovery/risk/validation-plan subagents when independent. Parent keeps destructive actions.
