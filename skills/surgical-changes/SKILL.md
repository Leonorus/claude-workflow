---
name: surgical-changes
description: Use on any code-editing task to restrict the blast radius. Touch only what the user asked for — no unrelated refactors, no drive-by formatting, no "while I'm here" cleanups.
---

# Surgical changes

Touch only what you were asked to touch. Clean up only your own mess.

## Why

Unrequested edits bloat diffs, hide the actual change, introduce bugs in unrelated code, and burn reviewer time. "While I'm here" is how one-line fixes become 300-line PRs that get rejected.

## When to invoke
- Every code-editing task. Especially active during **Ops/Infra**, **Go/Python app**, **Go/Python script**, and **Debug** (applying a fix).

## The rule

A diff may contain:
1. **Lines required by the user's request.**
2. **Lines required to make #1 work** (new imports, wiring, tests).
3. **Lines cleaning up code *you just wrote*** (typos, leftover prints).

A diff may NOT contain:
- Renaming variables unrelated to the change.
- Reformatting files the auto-formatter didn't already change.
- "Fixing" adjacent code that looks wrong but wasn't reported.
- Refactoring functions you didn't need to touch.
- Updating dependencies opportunistically.
- Deleting commented-out code you didn't add.

## If you see something genuinely wrong

Tell the user in your summary: "I noticed X in file Y:line Z — unrelated to this task. Want me to file a follow-up?" Do not fix it inline.

## Anti-patterns
- "I'll just tidy these imports since I'm editing this file."
- Auto-sorting keys in a config file where the user's change only added one key.
- Replacing `.format()` with f-strings in a function you happen to be near.
- Adding type hints to untyped code because "it's 2026."
