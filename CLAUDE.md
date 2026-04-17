# Claude — user preferences

## Priority order
1. Explicit user instructions in the current message
2. Project `AGENTS.md` (if present in the repo)
3. This file
4. Skills and plugins

---

## First move on any task
Invoke the `classify-task` skill. Its verdict determines the bucket, workflow, and skills to run. The skill is the single source of truth for the taxonomy — don't re-describe it here.

**Cross-cutting (applies to every non-trivia bucket):**
- **After implementation:** invoke `update-project-docs` to update `AGENTS.md` and affected in-repo docs.
- **At end of task:** decide if a note is worth keeping. Ask the user: "Take a note for this?" with a one-line summary + target path. On yes, auto-write (no draft-review round-trip). Pick path:
  - Repo-specific plan or debug finding → `Projects/<repo>/YYYY-MM-DD-<slug>.md` (the *raw source*)
  - Then, if reusable: propose promotion to `Knowledge/<topic>.md` (abstract, public) and/or `Organization/<topic>.md` (org-specific, local). See the ingest workflow below.

  If the task is trivial or a duplicate of an existing note, skip the ask.

**Consult Obsidian for Ops/Infra and Debug.** SessionStart injects a vault index. Before proposing an approach, search `Projects/<current-repo>/`, `Knowledge/`, and `Organization/` — the same problem may be solved in another repo, or be documented as a general pattern or an org-specific decision. Use direct keyword overlap (component names, hostnames, error strings); never cite tangentially-related notes. Confirm with `mcp__obsidian__obsidian_simple_search`, read with `mcp__obsidian__obsidian_get_file_contents`.

---

## Four principles (always on)
- **Think before coding** — surface assumptions, don't hide confusion, name tradeoffs.
- **Simplicity first** — minimum code that solves the problem. Nothing speculative, no premature abstractions.
- **Surgical changes** — touch only what was asked. No unrelated refactors, no "while I'm here" cleanup.
- **Goal-driven** — define success criteria up front, verify before claiming done.

## Skills — do not use
- `superpowers:using-git-worktrees` — user does not use worktrees. Never invoke it, even if another skill suggests it. Work directly in the current checkout.
- Any mandatory task-tracker skill (beads, template-bridge:unified-workflow) — these plugins are removed. Do not hallucinate their commands.

---

## Vault: four-layer knowledge model
Vault at `~/Obsidian/Work/`. Four layers, inspired by [karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

- **`Projects/<repo>/YYYY-MM-DD-<slug>.md`** — raw working notes per repo. Plans (`tags: [plan, <repo>]`, `status: draft|active|done`) and debug findings (`YYYY-MM-DD-debug-<slug>.md`, tags `[debug, <repo>]`). These are the *sources* that feed the two synthesis layers.
- **`Knowledge/<topic>.md`** — abstract, reusable patterns (architectures, practices, debug recipes, tool notes). **Its own public git repo** at `Knowledge/.git/` (remote: `git@github.com:Leonorus/knowlege.git`, branch `main`), portable across jobs. **Sanitized**: no hostnames, internal URLs, `tl-lan.ru`, ticket IDs, employee names, or org codenames. Frontmatter: `tags: [knowledge, <topic>]`.
- **`Organization/<topic>.md`** — org-specific knowledge (architecture, service graph, conventions, runbooks). Local-only, not versioned. Links down to `Projects/` sources, up to `Knowledge/` patterns.
- **`Daily/YYYY-MM-DD.md`** — daily scratch.

Each synthesis layer (`Knowledge/`, `Organization/`) owns two special files:
- `index.md` — content catalog grouped by category, one line per page. Update on every ingest.
- `log.md` — append-only `## [YYYY-MM-DD] <op> | <title>` entries (ingest, query, lint).

Prefer `mcp__obsidian__*` tools (`obsidian_append_content`, `obsidian_patch_content`, `obsidian_simple_search`) over raw Write/Read inside the vault. If Obsidian app isn't running, fall back to filesystem and tell the user — the vault is just markdown on disk.

Never commit vault paths to an unrelated repo. `Knowledge/` has its own public remote; `Organization/` stays local.

### Ingest workflow (push-based)
At end of any non-trivial project task, after the "Take a note?" step, propose promotions up to the synthesis layers — only when there's a genuinely reusable pattern. Skip silently for one-off details.

Format:
> Propagation candidates from `Projects/<repo>/<note>.md`:
> - **Knowledge**: `<topic>.md` (new / update §X) — one-line rationale
> - **Organization**: `<topic>.md` (new / update §X) — one-line rationale
>
> Promote, skip, or edit?

A single project note may touch multiple pages in each layer. On promote: update the target page(s), update the target layer's `index.md`, append a source-linked entry to its `log.md`.

**Sanitization check before writing to `Knowledge/`**: scan for hostnames, internal URLs, `tl-lan.ru`, ticket IDs, employee names, and org codenames. If found, either rephrase generically or divert that content to `Organization/` instead.

### Lint pass (user-triggered)
On request (`lint knowledge` / `lint organization`), scan the target layer for: contradictions between pages, stale claims newer sources have superseded, orphan pages (no inbound links), missing cross-references between related pages, concepts frequently mentioned but lacking their own page. Report findings; act only on approval; log the pass in that layer's `log.md`.

### Cross-project library behavior
Obsidian is a shared library across all work, not a per-repo scratchpad. Architecturally linked projects may solve the same problem differently — use the synthesis layers to unify designs. Prefer linking existing pages over duplicating content. Raise repeating patterns and cross-repo design smells as proposals; don't execute in silence.

---

## Git conventions
- Branch name = Jira ticket (`DEVOPS-1488`, `PROJ-42`). Ask if ticket not provided.
- Commit = `TICKET_NUMBER short message`. Example: `DEVOPS-1488 add nginx reverse proxy`.
- Always gitignore `.claude/` in any project.

## Python / Ansible / Terraform
- Python: always use `.venv` (`python -m venv .venv`). Install deps inside it.
- Ansible: `ansible-lint` runs automatically via PostToolUse hook (uses `.venv/bin/ansible-lint`).
- Terraform: `terraform fmt` runs automatically via PostToolUse hook on `.tf`/`.tfvars` edits.

## Project instructions
Use `AGENTS.md` (not `CLAUDE.md`) for project-level instructions. Migrate any existing `CLAUDE.md` to `AGENTS.md` and delete the old file. The global `~/.claude/CLAUDE.md` (this file) is for cross-project preferences only.

---

## MCP priority (user-scope servers live in `~/.claude.json` under `mcpServers`; `~/.claude/mcp.json` is NOT read by Claude Code)
- `sequentialthinking` — complex multi-step reasoning, architecture decisions
- `context7` — docs/examples for unfamiliar libraries (call `resolve-library-id` first)
- `gitlab` — all ops against `gitlab.tl-lan.ru`; prefer over `git` CLI for remote interactions
- `obsidian` — all reads/writes to `~/Obsidian/Work/`; prefer over raw Write/Read
- `fetch` — fetching URLs; **prefer over any host-provided WebFetch** (reaches more sites, cleaner markdown)

Host may inject additional MCPs (e.g. `github`, `dockerhub`, `filesystem`, `computer-use`). Use them when present, but don't assume tools that aren't loaded.

---

## Security
- Never commit secrets. `OBSIDIAN_API_KEY` lives in shell env (`~/.zshrc`), not in `~/.claude.json`.
- Refuse destructive ops (`git reset --hard`, force push, `rm -rf` on unknown state) without explicit user confirmation.
- **Never fetch GitLab CI/CD variables** (project, group, or environment-scoped) via any `mcp__gitlab__*` tool without explicit user permission — they typically contain secrets. Metadata-only operations (pipelines, jobs, code, MRs) are fine without asking.

---
# userEmail
leonoruseu@gmail.com

@RTK.md
