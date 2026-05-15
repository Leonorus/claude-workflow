# Claude Code — user-wide agent guidance

This file provides user-wide instructions for Claude Code across every project
under `/Users/filipp.vysokov`. It mirrors the current Codex/Hermes workflow while
using Claude Code's tool and MCP names.

## Priority order

1. Explicit user instructions in the current message
2. Project `AGENTS.md` in the current repo (if present)
3. This file
4. Skills and plugins

---

## First move on any task

Workflow: for substantial software/ops/debug/research/repo-maintenance, call the
Workflow MCP `start_task(prompt,cwd,repo)` tool first (Claude tool name is
normally `mcp__workflow__start_task`); state/override bucket, load returned
skills, follow contract/context/delegation/finish checklist. Use Workflow and/or
Obsidian MCP before Obsidian claims. Finish non-trivia with Workflow MCP
`finish_checklist` (normally `mcp__workflow__finish_checklist`). Fallback:
invoke the `classify-task` skill.

## Four principles

- Think before coding — surface assumptions, name unknowns, and state tradeoffs.
- Simplicity first — implement the minimum needed; avoid speculative flags,
  abstractions, or helpers.
- Surgical changes — touch only what was asked plus direct wiring/tests; report
  unrelated issues rather than fixing them inline.
- Goal-driven — define verifiable success criteria and execute until they pass
  before claiming done.

## Skills and plugins

Skills and plugins are a toolbox, not mandatory governance. Workflow MCP routes
substantial work into the right bucket and returns the contract/context/
delegation/checklist; `classify-task` is the fallback human-readable workflow
when Workflow MCP is unavailable or obviously wrong.

- Use returned skills from Workflow MCP instead of preloading broad workflow
  prose.
- Use Claude Code subagents only when they materially improve correctness or
  parallelism; keep destructive/user-facing actions in the main agent.
- Do not use git worktrees unless the user explicitly asks. Work directly in the
  current checkout.
- Do not invent tools — if a skill, plugin, or CLI is not documented here or in
  an available skill, ask or research it before invoking.
- Plugin skills (`superpowers:*`, `remember:*`, `claude-md-management:*`, etc.)
  are reusable tools. If a plugin's always-on protocol conflicts with this file,
  this file wins.

## Vault: five-layer knowledge model

Vault root: `~/Obsidian/Work/`.

Raw source layers:

- `Clippings/` — immutable external sources. Read and link; never edit, rename,
  or delete.
- `Projects/<repo>/YYYY-MM-DD-<slug>.md` — raw per-repo plans, debug notes, and
  findings. Editable while active; treated as source material after completion.

Synthesis layers:

- `Knowledge/<topic>.md` — abstract, reusable patterns portable across
  employers. Keep employer-specific details out.
- `Organization/<topic>.md` — org-specific architecture, service graph,
  conventions, and runbooks. Local-only, not versioned.

Scratch layer:

- `Daily/YYYY-MM-DD.md` — daily scratch and reports. Lint reports go under
  `Daily/Lint/`.

Each synthesis layer owns:

- `index.md` — content catalog grouped by category.
- `log.md` — append-only `## [YYYY-MM-DD] <op> | <title>` entries.

Promotion rules:

- Apply the abstract-pattern test before writing to `Knowledge/`: the page
  should plausibly apply at 5+ different employers.
- Put internal hostnames, ticket IDs, employee names, org codenames, concrete
  service graphs, and company-specific runbooks in `Organization/`.
- Use relative Obsidian links to sources such as `[[Clippings/foo.md]]` or
  `[[Projects/<repo>/2026-04-18-debug-x.md]]`.
- Never commit vault paths to unrelated repos.

Obsidian hooks are trigger-only. Do not infer or cite note candidates from hook
text. For Ops/Infra/Debug/architecture/reusable research, use Workflow MCP
`start_task`/`discover_context` or Obsidian MCP search, then read matching notes
before making claims.

## Git conventions

### Branches

- Branch names follow Jira ticket numbers: `DEVOPS-1488`, `PROJ-42`, etc.
- Ask for the Jira ticket number before creating branches or commits if it was
  not provided.

### Commits

- Format: `TICKET_NUMBER short_message_what_was_done`.
- Example: `DEVOPS-1488 add nginx reverse proxy configuration`.
- The ticket number must match the current branch name.
- Do not create commits without a Jira ticket unless the user explicitly asks to
  bypass this convention.
- Exception: personal config repositories such as `~/.claude` and
  `~/src/hermes-config` do not require Jira ticket prefixes; use concise
  conventional commit subjects there.

## Python / Ansible / Terraform

- Python: always use a project-local `.venv` (`python -m venv .venv`). Install
  dependencies inside it and prefer `.venv/bin/*` tools.
- Ansible: after editing playbooks, roles, templates, or variables, run
  `.venv/bin/ansible-lint` from the project root unless the repository already
  automates it.
- Terraform: after editing `.tf` or `.tfvars`, run `terraform fmt` on affected
  files or from the relevant root. When practical, run `terraform validate` in
  the relevant module/environment.

## Project instructions

- Use `AGENTS.md` for project-level instructions. Do not create new `CLAUDE.md`
  files.
- Keep `~/.claude/CLAUDE.md` only as Claude-specific global configuration.
- If a project already has `CLAUDE.md`, migrate relevant content into
  `AGENTS.md` and remove the old file when safe.
- Always ensure `.claude/` is listed in project `.gitignore`.

## Verification

- After code/config changes, run the smallest relevant verification first, then
  broaden scope only as needed.
- Prefer targeted tests for the changed area before full-suite runs.
- If no automated test exists, run the closest lint, type-check, build,
  smoke-check, formatter, or syntax check.
- Never claim success without stating what was actually verified.
- If verification could not run, say exactly why and name the missing command or
  dependency.
- For config-only or documentation-only changes, verify syntax, formatting,
  references, and cheaply exercisable examples.

## MCP and tooling preferences

User-scope MCP servers live in `~/.claude.json` under `mcpServers`; this repo's
`mcp.json` is the source file that `install.sh` merges into `~/.claude.json`.
Claude Code does not read `~/.claude/mcp.json` directly.

Mirrored from Codex/Hermes:

- `docker_gateway` — Docker MCP Gateway on `http://127.0.0.1:8811/mcp`, providing
  Docker-catalog tools such as GitHub, Docker Hub, Context7, Obsidian, fetch,
  filesystem, and sequential thinking.
- `gitlab` — direct GitLab MCP on `http://127.0.0.1:8812/mcp`; prefer it over
  ad-hoc API calls for GitLab remote metadata.
- `workflow` — Workflow MCP on `http://127.0.0.1:8813/mcp`; use it for task
  classification, context discovery, delegation hints, and finish checklists.

Use local `git` CLI for local workspace status, diffs, branches, staging,
rebases, and commits. Use MCP tools for remote metadata when available.

## Security

- Never commit secrets.
- Refuse destructive operations such as `git reset --hard`, force push, or
  `rm -rf` on unknown state without explicit user confirmation.
- Treat GitLab CI/CD variables as secrets; do not inspect them through MCP/API
  tools.
- GitLab MCP writes are denied in `settings.json`; remote mutations should go
  through explicit user-approved commands, not silent MCP writes.

## Working style

- Be pragmatic and direct.
- Preserve existing user changes. Do not revert unrelated work.
- Prefer non-interactive commands and explicit verification.
- When asked for review, default to finding bugs, regressions, risks, and
  missing tests first. Put findings before summaries.
- For implementation tasks, inspect existing project conventions before
  introducing new patterns.
- Prefer small, targeted changes over broad refactors unless explicitly
  requested.
- State assumptions when they materially affect the solution.

@RTK.md
