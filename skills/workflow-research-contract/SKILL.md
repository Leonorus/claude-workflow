---
name: workflow-research-contract
description: "Strict contract for source-backed exploration, comparison, options, or recommendations without code changes."
---

# Research workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Research`. This is a compact contract, not a prose tutorial.

## First move

State the question, decision needed, evidence bar, and assumptions.

## Context required

Use upstream docs/source and read relevant Obsidian notes via `mcp__docker_gateway__obsidian_*` when available for Ops/Infra, Debug, architecture, or reusable research. Candidate note paths are not evidence until read.

## Forbidden early actions

- Do not present assumptions as facts.
- Do not cite candidate paths or search snippets as if read.
- Do not edit files unless reclassified.

## Verification required

- Cite URLs/paths/notes actually read.
- Separate facts, assumptions, risks, confidence, and unknowns.
- Include next checks when confidence is below decision threshold.

## Finish condition

Return facts with sources, recommendation, confidence, risks, unknowns, and no code-change claim.

## When to escalate bucket

- Implementation requested: App Code/Script/Light Ops/Heavy Ops as appropriate.
- Architecture/rollback/prod decision: reasoning guard required.

## When to use subagents

Use 2-3 read-only researchers when scope permits: upstream docs/source, local repo context, prior Obsidian/org knowledge.
