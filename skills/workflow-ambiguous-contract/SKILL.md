---
name: workflow-ambiguous-contract
description: "Strict contract for unclear prompts where bucket/tool choice changes with interpretation."
---

# Ambiguous workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Ambiguous`. This is a compact contract, not a prose tutorial.

## First move

Ask one concise clarifying question, or proceed only with an explicit low-risk assumption.

## Context required

No extra context gathering beyond what is needed to clarify safely.

## Forbidden early actions

- Do not edit files while material scope ambiguity remains.
- Do not spawn subagents into unclear requirements.
- Do not choose a high-risk interpretation silently.

## Verification required

- After clarification, reclassify and follow the selected bucket contract.
- If proceeding under assumption, verify only the low-risk assumed scope.

## Finish condition

State the clarified bucket or the explicit assumption used, then follow that bucket finish condition.

## When to escalate bucket

- Any high-risk or destructive possibility remains unresolved: ask rather than act.
- User clarifies into a concrete bucket.

## When to use subagents

Do not use subagents until clarified.
