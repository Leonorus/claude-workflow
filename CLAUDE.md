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
- **At end of task:** propose an Obsidian note. Pick path:
  - Reusable pattern / architectural decision / cross-project → `Knowledge/<topic>.md`
  - Repo-specific plan or debug finding → `Projects/<repo>/YYYY-MM-DD-<slug>.md`
  Draft the note, show the user the draft + target path, write on confirm. Don't auto-write.

**Consult Obsidian for Ops/Infra and Debug.** SessionStart injects a vault index. Before proposing an approach, search **both** `Projects/<current-repo>/` **and** `Knowledge/` — the same problem may be solved in another repo. Use direct keyword overlap (component names, hostnames, error strings); never cite tangentially-related notes. Confirm with `mcp__obsidian__obsidian_simple_search`, read with `mcp__obsidian__obsidian_get_file_contents`.

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

## Plans, notes, knowledge → Obsidian
Vault at `~/Obsidian/Work/`:
- **Plans/specs** → `Projects/<repo-name>/YYYY-MM-DD-<slug>.md`, frontmatter `tags: [plan, <repo>]`, `status: draft|active|done`.
- **Debug findings** → `Projects/<repo-name>/YYYY-MM-DD-debug-<slug>.md`, tags `[debug, <repo>]`.
- **Reusable knowledge** → `Knowledge/<topic>.md`, tags `[knowledge, <topic>]`.
- **Daily scratch** → `Daily/YYYY-MM-DD.md`.

Prefer `mcp__obsidian__*` tools (`obsidian_append_content`, `obsidian_patch_content`, `obsidian_simple_search`) over raw Write/Read inside the vault. If Obsidian app isn't running, fall back to raw filesystem Write and tell the user — the vault is just markdown on disk.

Never commit Obsidian vault paths to a repo. `~/Obsidian/` lives outside repos by design.

### Obsidian as cross-project library
Obsidian isn't a per-repo scratch pad — it's a shared library across all this user's work.
- Architecturally linked projects may solve the same problem differently; use Obsidian to unify those designs.
- When a pattern repeats across 2+ repos, promote the finding from a project note to `Knowledge/<topic>.md` and cross-link the source projects by relative path.
- Prefer linking existing `Knowledge/` notes over duplicating content.
- Before implementing an Ops/Infra or Debug approach, search `Knowledge/` — not just the current project's folder.
- Insights welcome: if during any task you notice a pattern repeating, a design smell across repos, or an opportunity to unify — raise it to the user as a proposal, don't just execute in silence.

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

---
# userEmail
leonoruseu@gmail.com
