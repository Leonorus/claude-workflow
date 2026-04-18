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

## Skills — toolbox, not governance
Governance = this file + custom skills (`classify-task`, the four principles, `architecture-review`, `update-project-docs`). Plugins (`superpowers:*`, `engram:*`, `remember:*`, `claude-md-management:*`) are a **toolbox** — invoke when a specific tool fits, not as mandatory always-on gates. If a plugin skill's "ALWAYS ACTIVE" protocol contradicts `classify-task` or the four principles, `classify-task` wins.

`superpowers:brainstorming` / `writing-plans` / `test-driven-development` / `systematic-debugging` / `verification-before-completion` / `requesting-code-review` / `receiving-code-review` / `finishing-a-development-branch` are good tools. They fire when `classify-task` routes into a bucket that calls for them, not on every turn.

### Do not use
- `superpowers:using-git-worktrees` — user does not use worktrees. Never invoke it, even if another skill suggests it. Work directly in the current checkout.
- Any mandatory task-tracker skill (beads, template-bridge:unified-workflow) — these plugins are removed. Do not hallucinate their commands.

---

## Vault: five-layer knowledge model
Vault at `~/Obsidian/Work/`. Five layers, inspired by [karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f):

**Raw sources (inputs — feed the synthesis layers):**
- **`Clippings/`** — external raw sources: web articles (via Obsidian Web Clipper), papers, vendor docs, RFCs, post-mortems. **Immutable**: the LLM reads from `Clippings/` but never writes, edits, renames, or deletes there. This is the source of truth for external material.
- **`Projects/<repo>/YYYY-MM-DD-<slug>.md`** — internal working notes per repo. Plans (`tags: [plan, <repo>]`, `status: draft|active|done`) and debug findings (`YYYY-MM-DD-debug-<slug>.md`, tags `[debug, <repo>]`). Editable while active; treated as sources once the task is done.

**Synthesis (compiled knowledge — LLM-maintained):**
- **`Knowledge/<topic>.md`** — abstract, reusable patterns (architectures, practices, debug recipes, tool notes). **Its own public git repo** at `Knowledge/.git/` (remote: `git@github.com:Leonorus/knowledge.git`, branch `main`), portable across jobs. **Sanitized**: no internal hostnames or URLs, ticket IDs, employee names, or org codenames. Frontmatter: `tags: [knowledge, <topic>]`.
- **`Organization/<topic>.md`** — org-specific knowledge (architecture, service graph, conventions, runbooks). Local-only, not versioned. Links down to `Clippings/` and `Projects/` sources, up to `Knowledge/` patterns.

**Scratch:**
- **`Daily/YYYY-MM-DD.md`** — daily notes; also where lint reports are appended.

Each synthesis layer (`Knowledge/`, `Organization/`) owns two special files:
- `index.md` — content catalog grouped by category, one line per page. Update on every ingest.
- `log.md` — append-only `## [YYYY-MM-DD] <op> | <title>` entries (ingest, query, lint).

Prefer `mcp__obsidian__*` tools (`obsidian_append_content`, `obsidian_patch_content`, `obsidian_simple_search`) over raw Write/Read inside the vault. If Obsidian app isn't running, fall back to filesystem and tell the user — the vault is just markdown on disk.

Never commit vault paths to an unrelated repo. `Knowledge/` has its own public remote; `Organization/` stays local.

### Ingest workflows
Two ingest paths — same output shape (updates to synthesis layers + index + log entry), different triggers.

**A. Push from `Projects/` (end-of-task).** After the "Take a note?" step, propose promotions up to the synthesis layers — only when there's a genuinely reusable pattern. Skip silently for one-off details.

> Propagation candidates from `Projects/<repo>/<note>.md`:
> - **Knowledge**: `<topic>.md` (new / update §X) — one-line rationale
> - **Organization**: `<topic>.md` (new / update §X) — one-line rationale
>
> Promote, skip, or edit?

**B. Pull from `Clippings/` (on demand).** When the user asks to ingest a clipping (by name, or "ingest new clippings"), read the clipped file, summarize the key takeaways, then propose the same propagation format. Never modify the clipping itself — link to it from the synthesis pages instead.

**Rules that apply to both paths:**
- A single source may touch multiple pages in each layer. On promote: update the target page(s), update the target layer's `index.md`, append a source-linked entry to its `log.md`.
- **Sanitization check before writing to `Knowledge/`**: scan for internal hostnames and URLs, ticket IDs, employee names, and org codenames. If found, either rephrase generically or divert that content to `Organization/` instead.
- Every synthesis page that cites a source must use a relative link (e.g. `[[Clippings/foo.md]]` or `[[Projects/<repo>/2026-04-18-debug-x.md]]`), so Obsidian's graph view shows the source trail.

### Lint pass (user-triggered + weekly cron)
On request (`lint knowledge` / `lint organization`), or automatically Mondays 10:00 local via the `com.filipp.weekly-knowledge-lint` launchd agent, scan the synthesis layers for: contradictions between pages, stale claims newer sources have superseded, orphan pages (no inbound links), missing cross-references between related pages, concepts frequently mentioned but lacking their own page. Also flag **un-ingested clippings** — files in `Clippings/` not referenced by any page in `Knowledge/` or `Organization/`. Report findings to `Daily/<today>.md`; act only on approval; log the pass in each synthesis layer's `log.md`.

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
- `gitlab` — all ops against the configured GitLab host; prefer over `git` CLI for remote interactions
- `obsidian` — all reads/writes to `~/Obsidian/Work/`; prefer over raw Write/Read
- `fetch` — fetching URLs; **prefer over any host-provided WebFetch** (reaches more sites, cleaner markdown)

Host may inject additional MCPs (e.g. `github`, `dockerhub`, `filesystem`, `computer-use`). Use them when present, but don't assume tools that aren't loaded.

---

## Security
- Never commit secrets. `OBSIDIAN_API_KEY` lives in shell env (`~/.zshrc`), not in `~/.claude.json`.
- Refuse destructive ops (`git reset --hard`, force push, `rm -rf` on unknown state) without explicit user confirmation.
- **GitLab CI/CD variable tools are denied at the permission layer** (`mcp__gitlab__*variable*` in `settings.json` → `permissions.deny`). They typically contain secrets; use the GitLab UI if you need to inspect them.
- **GitLab writes are denied by default** (`create_*`, `update_*`, `delete_*`, `merge_*`, `approve_*`, `push_*`, etc. in `settings.json` → `permissions.deny`). Remote mutations go through shell `git` / `glab` with explicit user approval, not through the MCP.

@RTK.md
