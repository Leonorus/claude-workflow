---
name: architecture-review
description: Use after implementation is complete and code review has passed, on any non-trivia bucket (ops/infra, go-python-app, go-python-script, debug with fix). Dispatches a subagent to read the diff plus affected modules and report design smells — misplaced responsibilities, premature or missing abstractions, tight coupling, file-size signals, duplication — with concrete suggestions.
---

# Architecture review

Code review catches "does this work". Architecture review catches "should it exist, here, like this".

## When to invoke
- After code review passes (or after implementation for buckets that skip code review).
- On every non-trivia bucket: **Ops/Infra**, **Go/Python app**, **Go/Python script**, **Debug (when a fix shipped)**.
- Skip for **Trivia** and **investigation-only Debug**.
- Skip for **Research** unless it produced recommendations that will be acted on.

## What to do

1. Identify the diff: staged + unstaged changes in the repo, or the recent edits in this session if not yet committed.
2. Identify the surrounding modules those changes touch — one hop of imports / includes / requires.
3. Dispatch a code-reviewer subagent with an architecture-focused prompt (see below).
4. Surface the report to the user. For each finding, say whether it's **blocking** (must fix before merge), **suggestion** (consider), or **note** (future-you should know).

## Subagent prompt template

```
Review the architecture of these changes. Context:
- Files changed: <list>
- One-hop neighbors: <list>
- Bucket: <bucket from classify-task>

Look specifically for:
1. Misplaced responsibilities — logic in the wrong layer/module/role.
2. Premature abstractions — base classes/interfaces/generics with one user.
3. Missing abstractions — duplicated logic across 3+ call sites that should be unified.
4. Tight coupling — a change here forces changes in unrelated places.
5. File-size signals — any file > 400 lines or function > 80 lines doing too much.
6. Naming — names that lie, generic names in specific contexts.
7. For Ansible: role boundaries (one role doing multiple jobs), task/handler mix-up, vars leaking across roles.
8. For Terraform: module granularity, inappropriate use of count/for_each, state-file scope.
9. For Go/Python app: package cohesion, circular imports, test/code boundary.
10. Cross-repo reuse — is any pattern introduced here already present in another repo the user maintains? If the subagent spots one, flag it as a **promotion candidate**: the pattern belongs in `~/Obsidian/Work/Knowledge/<topic>.md` with cross-links back to the source repos.

Do NOT comment on correctness, style, or formatting — code review already covered that.
Report each finding with: severity (blocking/suggestion/note), file:line, what, why it matters, concrete suggestion.
If the architecture is fine, say so in one sentence.
```

## After the report
- Blocking findings → fix before marking the task done.
- Suggestions → discuss with user; log non-adopted ones in Obsidian under `Projects/<repo>/<date>-arch-notes.md`.
- Notes → optionally log in same place.
- **Promotion candidates** → draft a `Knowledge/<topic>.md` entry that extracts the shared pattern; show the user the draft + target path; write on confirm. Cross-link the source repos by relative path.

## Anti-patterns
- Running architecture review before code review (wastes time if correctness is broken).
- Skipping it on Ops/Infra ("Ansible doesn't have architecture") — it does: role boundaries, module reuse, secrets layering.
- Accepting vague feedback. If the subagent says "consider refactoring", ask for the specific shape of the refactor.
