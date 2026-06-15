---
name: workflow-trivia-contract
description: "Strict contract for tiny factual/mechanical work in the workflow bucket taxonomy."
---

# Trivia workflow contract

Use this when Workflow MCP or `codex-workflow` classifies the task as `Trivia`. This is a compact contract, not a prose tutorial.

## First move

Answer directly or make the tiny obvious change.

## Context required

No plan, Obsidian, subagent, or companion skill unless the user explicitly asks or the tiny change touches files/commands.

## Forbidden early actions

- Do not expand scope.
- Do not add workflow overhead just because a tool is available.
- Do not write notes.

## Verification required

- If no file/command changed, no verification is required.
- If a file changed, run the cheapest syntax/format/reference check available.

## Finish condition

State the answer/change and any cheap check performed. No finish checklist unless files or commands changed.

## When to escalate bucket

- The request touches prod/secrets/network/runtime state.
- The diff stops being obvious or spans multiple files.
- There is a real failure to diagnose.

## When to use subagents

Never use subagents for Trivia.
