---
name: workflow-planning-contract
description: "Strict contract for producing a reviewable, actionable build plan before committing to execution; the plan is the deliverable."
---

# Planning workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Planning`. This is a compact contract, not a prose tutorial. Planning presupposes intent to build and produces an actionable, sequenced plan; it is distinct from Research, which answers an open question. The two chain (decide *whether*, then plan *how*); they do not compete.

## First move

State the goal in one sentence, the load-bearing assumptions, the unknowns, and the success criteria that make a plan "done". Do not propose steps yet.

## Context required

Read the relevant repo files and directly-relevant Obsidian `Projects/`, `Knowledge/`, and `Organization/` notes via the Obsidian MCP before proposing an approach. Candidate paths are not evidence until read.

## Process

1. Refine intent — ask clarifying questions one at a time until purpose, constraints, and success criteria are unambiguous. No plan before intent is clear.
2. Propose 2-3 approaches with trade-offs and a recommendation; get the user to pick before detailing.
3. Author the plan — sequenced, independently-verifiable steps; each step names its verification; call out risks, rollback, and what is explicitly out of scope.

## Forbidden early actions

- Do not edit code or config (planning produces a document, not a diff).
- Do not present approaches as decided before the user picks.
- Do not skip intent-refinement because the task "looks clear".

## Verification required

- Plan self-review: no TBDs/placeholders, no step contradicts another, every step is verifiable, scope is single-plan-sized (decompose if not).
- Get explicit user approval of the plan.

## Finish condition

Write the approved plan as an Obsidian project note `Projects/<repo>/YYYY-MM-DD-<slug>-plan.md` via the Obsidian MCP. Default = stop here; the plan is the deliverable. Then state the promotion decision (below).

## When to escalate bucket

On an explicit execute-now intent ("now do it", "go ahead", "ship it"), reclassify into the real execution bucket (Heavy Ops / App Code / Script / Light Ops) via a fresh `start_task`, feeding the plan note path as context. This is the promotion mechanism; default remains stop-at-approved-plan.

## When to use subagents

Use read-only explorers/researchers to gather context and pressure-test candidate approaches in parallel; the parent owns the plan and the user dialogue.
