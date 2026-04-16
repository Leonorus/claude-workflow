# Claude — user preferences

## Priority order
1. Explicit user instructions in the current message
2. Project `AGENTS.md` (if present in the repo)
3. This file
4. Skills and plugins

---

## First move on any task
Classify the request into one of the buckets below and apply that weight. If you cannot classify confidently, **ask the user** before proceeding.

| Bucket | Signals | Weight |
|---|---|---|
| **Trivia** | typo, rename, one-line config tweak, obvious doc fix | Just do it. No workflow, no arch review. |
| **Ops / Infra** | Ansible, Terraform, shell, k8s, CI, Dockerfile | Short plan if >1 file. No TDD. Dry-run / `--check` / `plan` before apply. Arch review. Doc update. |
| **Go / Python app code** | `go.mod` or `pyproject.toml` present, has tests dir, real module | Full weight: brainstorm → plan → **TDD** → code review → arch review → verify → doc update. |
| **Go / Python script** | single-file, glue/automation, <~100 lines | Short plan if non-trivial. No TDD (manual smoke test). Arch review. Doc update. |
| **Debug** | bug report, test failure, stack trace, "why is X broken" | `systematic-debugging`: hypothesis → minimal repro → instrument → fix → verify. No speculative fixes. |
| **Research** | "how does X work", "compare A vs B" — no bug, just learning | Read, investigate, report. No workflow weight. Write findings to Obsidian. |
| **Ambiguous** | Can't confidently classify, spans buckets | **Ask the user** which bucket + scope first. |

**Two cross-cutting rules:**
- **After code/config change (non-trivia):** update `AGENTS.md` and affected docs in the repo.
- **Plans, specs, research notes go to Obsidian**, not the repo.

**Consult Obsidian for Ops/Infra and Debug buckets.** A vault index is injected at SessionStart (paths + tags from `~/Obsidian/Work/`). Before proposing fixes or runbooks, scan that index — if anything looks related, call `mcp__obsidian__obsidian_simple_search` with keywords from the request and read matching notes via `mcp__obsidian__obsidian_get_file_contents` *before* answering. Cite the note path when you use one.

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
