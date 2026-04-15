---
name: simplicity-first
description: Use while writing or reviewing any code change. Enforces minimum code that solves the stated problem — no speculative features, no premature abstractions, no frameworks for problems that haven't appeared.
---

# Simplicity first

Minimum code that solves the problem. Nothing more.

## The rule

If a piece of code isn't required by an explicit, current user need, don't write it. "We might need it later" is not a need.

## When to invoke
- Any bucket that produces code: **Ops/Infra**, **Go/Python app**, **Go/Python script**, **Debug** (when applying a fix).
- Skip for **Trivia** (by definition trivia is already minimal) and pure **Research**.

## What to do

Before merging / committing, scan the diff and remove:

- **Speculative features.** Config flags, options, parameters that have one caller and no planned second caller.
- **Premature abstractions.** Base classes / interfaces with one implementation. Generic wrappers around one concrete thing.
- **Unrequested error handling.** Try/except around code that can't fail in practice. Validation for inputs that come from trusted internal callers.
- **"Nice to have" extras.** Logging sprinkled everywhere, metrics on one-shot scripts, docstrings on obvious one-liners.
- **Dead branches.** `if legacy_mode:` paths for a feature flag nobody flips, compatibility shims for callers that don't exist.

## Tests for "is this speculative?"

Ask the user's stated problem. Does the code line/branch/file exist to solve *that* problem? If yes, keep it. If it exists to solve some adjacent or hypothetical problem, cut it.

## Anti-patterns
- "Just in case" validation at internal boundaries.
- Wrapping a single `requests.get` in a `Client` class with a `retry_policy` arg.
- Creating `utils/`, `helpers/`, `common/` with one function inside.
- `if __name__ == "__main__":` blocks that do something different from the documented behavior.
