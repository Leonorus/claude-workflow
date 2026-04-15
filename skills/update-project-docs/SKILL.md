---
name: update-project-docs
description: Use as the final step after any non-trivia code or config change in a repo. Updates the project's AGENTS.md and any affected in-repo docs (README, runbooks, module READMEs) to reflect what changed, so future Claude sessions start from accurate context.
---

# Update project docs

After the code is right, the docs have to match. Otherwise the next session builds on stale context and makes things worse.

## When to invoke
- Final step of **Ops/Infra**, **Go/Python app**, **Go/Python script**, and **Debug (when a fix shipped)** buckets.
- Skip for **Trivia** and **investigation-only Debug** and **Research** (research writes to Obsidian, not repo).

## Scope — what counts as "docs"

Within the repo:
- `AGENTS.md` (or `CLAUDE.md` migrated to it) — agent instructions, gotchas, project-level preferences.
- `README.md` — user-facing overview, quickstart, commands.
- `docs/` or equivalent — runbooks, ADRs, architecture notes.
- Module-level READMEs in Go / Ansible roles / Terraform modules.

Out of scope (don't touch):
- `CHANGELOG.md` unless the user asked (release process is theirs).
- Generated docs.
- Wiki / external docs.

## Procedure

1. **Diff the change.** Identify what behavior, interface, or convention changed.
2. **Grep the docs.** Look for text that referenced the old behavior — old command names, removed flags, deprecated paths, assumption statements that are now wrong.
3. **Edit surgically.** Update only the sentences/sections that became inaccurate. Do not rewrite docs that are still correct.
4. **Add to `AGENTS.md`** if the change introduced:
   - A new convention ("all new handlers must go in `internal/handler/`").
   - A new gotcha ("never run migrations without `--dry-run` first in prod").
   - A new command / workflow step.
5. **Verify.** Read the updated sections back. Does a fresh reader now get the right picture?

## Format for AGENTS.md additions

Prefer a short "Gotchas" or "Conventions" subsection with:
- **What** (one line)
- **Why** (one line — rationale, so future-you can judge edge cases)

Example:
```
### Gotchas
- **Never import internal/db from cmd/.** The cmd layer must go through internal/service — enforced to keep transactions scoped to a request.
```

## Anti-patterns
- Opening doc files, skimming, and saying "looks fine" without grep-verifying.
- Adding generic advice that isn't tied to a specific gotcha in *this* repo.
- Rewriting existing accurate prose for style.
- Leaving stale command examples ("`make deploy-old`" after you removed the target).
