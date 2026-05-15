# claude-workflow

A focused, context-aware workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). It mirrors the Codex/Hermes workflow: Workflow MCP classifies substantial tasks into buckets (trivia / light-ops / heavy-ops / app-code / script / debug / research / repo-maintenance / ambiguous) and applies weight proportional to what the task actually needs. Light tasks can **escalate to heavy mid-flight** when scope turns out bigger than stated. Karpathy-style meta-principles (think before coding, simplicity, surgical changes, goal-driven execution) run across all of them.

Plans and research live in an Obsidian vault outside any repo, treated as a **cross-project knowledge library** — patterns that repeat across repos get promoted to `Knowledge/<topic>.md` with cross-links. Architecture review and project-doc updates are first-class steps of the workflow, not afterthoughts.

## Why this exists

The default "install every plugin, run every gate on every task" setup produces two failure modes:

1. **Mandate mismatch.** A one-line typo and a 2000-line feature get the same 10-step checklist. So the checklist gets ignored.
2. **Competing authorities.** Five plugins plus a long `CLAUDE.md` plus SessionStart hooks all inject overlapping workflow rules. The agent picks the path of least resistance — often none of them.

This repo is the minimum-viable reset: a short `CLAUDE.md` with priority order and Workflow MCP first-move rule, fallback skills, trigger-only hooks, and the specific MCP servers actually in use. Nothing that is not earning its keep.

## What's in the repo

```
.
├── CLAUDE.md                    User-level preferences, 4 principles, MCP priority (taxonomy lives in classify-task skill)
├── RTK.md                       RTK (Rust Token Killer) reference — imported into CLAUDE.md via `@RTK.md`
├── settings.json                Plugin list, hooks (ansible-lint, terraform-fmt, auto-sync, obsidian-index, rtk)
├── mcp.json                     User-scope MCP servers (Docker Gateway + GitLab + Workflow HTTP)
├── statusline-command.sh        Custom status line (cwd, branch, context %, rate-limit %)
├── auto-sync.sh                 Stop-hook: commits and pushes tracked changes after each turn
├── hooks/
│   └── obsidian-index.sh        SessionStart hook: trigger-only Obsidian reminder
├── skills/
│   ├── classify-task/           Fallback classifier when Workflow MCP is unavailable
│   ├── think-before-coding/     Surface assumptions + tradeoffs before editing
│   ├── simplicity-first/        Minimum code, nothing speculative
│   ├── surgical-changes/        Touch only what was asked
│   ├── goal-driven-execution/   Define "done", verify, don't claim without evidence
│   ├── architecture-review/     Dispatches subagent for design-smell pass
│   └── update-project-docs/     Post-change update of AGENTS.md + docs
├── scheduled-tasks/             Headless Claude jobs run by macOS launchd
│   ├── daily-mr-report/         Weekday 9:00 — appends GitLab MR digest to Daily/<today>.md
│   └── weekly-knowledge-lint/   Monday 10:00 — lints Knowledge/ + Organization/, reports to Daily/
└── .gitignore                   Allowlist — everything ignored unless explicitly permitted
```

## Task routing (the core idea)

Workflow MCP is the preferred front door. It returns the bucket, matching contract,
context candidates, delegation hints, and finish checklist. The fallback
`classify-task` skill uses the same buckets:

| Bucket | Trigger signals | Weight |
|---|---|---|
| **Trivia** | typo, one-line obvious doc/config fix | Just do it. No workflow. |
| **Light Ops** | small single-file Ansible/Terraform/k8s/CI/Docker change with no direct prod/secret/network/apply boundary | Inspect convention → edit surgically → targeted lint/fmt/check → summarize. |
| **Heavy Ops** | multi-file ops, actual prod boundary, secrets/network/security, new role/module/stack, architectural shift, repeated pattern | Name blast radius/rollback or dry-run path → consult Workflow/Obsidian context → plan → validate/render/dry-run/smoke → docs/note. |
| **App Code** | behavior/API/module change, tests present, multiple packages/modules | Define success → targeted test first where practical → implement → targeted tests → docs if behavior changed. |
| **Script** | glue/automation/hook/cron/LaunchAgent/local service | Define input/output/exit codes/idempotency/side effects → inspect runtime conventions → syntax check + safe smoke test. |
| **Debug** | bug report, failing test, stack trace, unexpected behavior | Reproduce/observe → hypotheses → inspect/instrument → fix cause → verify exact failure is gone. |
| **Research** | compare/explore/understand, no code change | Read sources/notes → report facts, assumptions, recommendation, confidence, risks, next checks. |
| **Repo-maintenance** | dependency/CI/docs/tests/release/config hygiene | Check status/diff → inspect convention → edit surgically → affected validation. |
| **Ambiguous** | multiple buckets fit or scope changes tool choice | Ask one concise clarifying question or proceed only with explicit low-risk assumption. |

Light Ops escalates to Heavy Ops when scope, diff size, or blast radius grows.
Do not treat the word “prod” alone as Heavy Ops when the change is only CI/list/
matrix wiring with variable names/placeholders and no secret values, runtime
config, RBAC, network policy, state, Helm values, or direct deploy.

## Subagent fan-out (Heavy Ops / app code)

**Rule: fan out any step that reads without writing, join in main.** Context isolation sharpens precision on big tasks — but only when the fan-out targets are genuinely independent.

- **Fan out** (parallel subagents via `superpowers:dispatching-parallel-agents`): Obsidian `Projects/<repo>/` + `Knowledge/` searches, docs lookups through Docker Gateway tools (for example Context7/fetch), inventory scans ("all call sites of X", "every role implementing pattern Y"), per-file lint on independent modules, architecture review (already a subagent by design).
- **Stay in main**: brainstorm, plan writing, editing, the mandatory dry-run gate, apply/commit/MR, doc synthesis, Obsidian note writes. Sequential, feedback-heavy, or destructive steps don't benefit from fan-out.

Each subagent returns a short structured report; main integrates before the next sequential step. Conflicts get resolved in main, not by delegation.

## Four always-on principles

1. **Think before coding** — surface assumptions, don't hide confusion, name tradeoffs.
2. **Simplicity first** — minimum code that solves the problem. Nothing speculative.
3. **Surgical changes** — touch only what was asked. No unrelated refactors.
4. **Goal-driven execution** — define success criteria up front, verify before claiming done.

## Obsidian as cross-project library (five-layer model)

`~/Obsidian/Work/` is not a per-repo scratch pad — it's a shared library across all work. The layout is inspired by [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): raw sources feed persistent, LLM-maintained synthesis layers that compound over time instead of being re-derived per query.

**Raw sources (LLM reads, rarely writes):**
- **`Clippings/`** — external raw material: web articles (via Obsidian Web Clipper), papers, vendor docs, RFCs, post-mortems. **Immutable.**
- **`Projects/<repo>/YYYY-MM-DD-<slug>.md`** — internal working notes per repo: plans, debug findings.

**Synthesis (LLM-maintained wiki):**
- **`Knowledge/<topic>.md`** — abstract, reusable patterns. **Own public git repo** (`Leonorus/knowledge` on GitHub), portable across jobs. Sanitized: no hostnames, internal URLs, tickets, employee names.
- **`Organization/<topic>.md`** — org-specific architecture and conventions. Local-only.

Each synthesis layer has an `index.md` (content catalog) and a `log.md` (append-only ingest/query/lint record).

**Scratch:** `Daily/YYYY-MM-DD.md` — daily notes; also where scheduled-task reports land.

**Ingest.** Two paths, same shape: (a) push from `Projects/` at end of task, (b) pull from `Clippings/` on demand. Both offer to propagate into `Knowledge/` and/or `Organization/`, update the target layer's `index.md`, and append to `log.md`. The `architecture-review` skill flags promotion candidates during its post-implementation pass.

**Search before acting.** Before implementing an Ops/Infra or Debug approach, use Workflow MCP context discovery or targeted Obsidian MCP search under `Projects/<current-repo>/`, `Knowledge/`, and `Organization/` — the same problem may already be solved in another repo, a general pattern, or an org-specific decision. Read matching notes before citing them.

**Lint.** Weekly (via `scheduled-tasks/weekly-knowledge-lint`) or on-demand: contradictions, orphan pages, missing cross-refs, ghost concepts, un-ingested clippings, and sanitization violations in `Knowledge/`.

At the end of non-trivia tasks, Claude asks "Take a note for this?" with a one-line summary + target path. On yes, the note is written automatically — no draft-review round-trip. Trivial tasks and duplicates are skipped without asking.

## Installation

```bash
# 1. Back up your current ~/.claude/ (important!)
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# 2. Clone this repo as your new ~/.claude/
git clone git@github.com:Leonorus/claude-workflow.git ~/.claude

# 3. Merge MCP servers into ~/.claude.json (Claude Code does NOT read ~/.claude/mcp.json)
~/.claude/install.sh

# 4. Restart Claude Code so settings.json and ~/.claude.json are re-read
```

If you already have customizations you want to keep, clone into a scratch directory and merge by hand.

### What `install.sh` does
Claude Code reads user-scope MCP servers from `~/.claude.json` — **not** from `~/.claude/mcp.json` inside this repo. `install.sh` backs up `~/.claude.json`, prunes legacy direct Docker MCP servers superseded by the shared Docker MCP Gateway, and merges the servers declared in `mcp.json` (`docker_gateway`, `gitlab`, `workflow`). Re-run after editing `mcp.json`. Requires `jq` (`brew install jq`).

### Post-install one-time setup

1. **Obsidian vault.** Create `~/Obsidian/Work/` with `Clippings/`, `Projects/`, `Knowledge/`, `Organization/`, and `Daily/` subdirectories. Open the folder as a vault in the Obsidian desktop app. For the `Knowledge/` layer, clone the knowledge repo into it: `git clone git@github.com:Leonorus/knowledge.git ~/Obsidian/Work/Knowledge` (or your own fork).
2. **Shared MCP services.** Start the same local services used by Codex/Hermes before launching Claude Code: Docker MCP Gateway on `127.0.0.1:8811`, GitLab MCP on `127.0.0.1:8812`, and Workflow MCP on `127.0.0.1:8813`. The Docker Gateway header uses `MCP_GATEWAY_AUTH_TOKEN` from the shell environment; keep the value out of git.
3. **Obsidian Local REST API plugin.** Required by the Obsidian MCP exposed through Docker Gateway. In Obsidian: Settings → Community plugins → Browse → install **Local REST API** → enable → export its API key in the environment consumed by the gateway.
4. **(Optional) Edit paths in `settings.json`** if your home directory isn't `/Users/filipp.vysokov`. Look for absolute paths in the `statusLine` and `Stop` hook entries.
5. **(Optional) Enable scheduled tasks.** Each job under `scheduled-tasks/` ships a macOS launchd plist next to its `run.sh`. To activate:
   ```sh
   # Edit the plist paths first if your $HOME is not /Users/filipp.vysokov,
   # then install each one:
   for p in ~/.claude/scheduled-tasks/*/com.filipp.*.plist; do
     cp "$p" ~/Library/LaunchAgents/
     launchctl load ~/Library/LaunchAgents/$(basename "$p")
   done
   ```
   Remove any you don't want with `launchctl unload` + `rm ~/Library/LaunchAgents/com.filipp.<name>.plist`. Each task's `SKILL.md` documents what it does and where its report lands.

## Dependencies

### Required

- **[Claude Code](https://docs.anthropic.com/en/docs/claude-code)** — the CLI this config targets.
- **[Docker](https://www.docker.com/)** — required for the shared Docker MCP Gateway service.
- **[Obsidian](https://obsidian.md/)** — required for plans/notes routing and the Obsidian MCP exposed through the gateway.
- **[Obsidian Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api)** — bridge between Obsidian and the MCP server.

### Homebrew tools

Both are wired in via this config — `rtk` as a `PreToolUse` hook in `settings.json`, `engram` as a Claude Code plugin providing the `mem_*` memory tools.

```sh
# RTK — Rust Token Killer, CLI proxy for 60–90% token savings on dev ops
brew install rtk

# Engram — persistent memory for AI coding agents (survives across sessions)
brew install gentleman-programming/tap/engram
```

- **[rtk](https://www.rtk-ai.app/)** — filters verbose output from git/docker/npm/etc. before it enters the context window. See the `## Token optimization (RTK)` section below and `RTK.md`.
- **[engram](https://github.com/Gentleman-Programming/engram)** — agent-agnostic persistent memory, single binary. Provides `mem_save` / `mem_search` / `mem_context` and related tools (active protocol runs at every SessionStart; the plugin's skill enforces proactive saves on decisions, bug fixes, and conventions).

### MCP servers

- `docker_gateway` — shared Docker MCP Gateway on `http://127.0.0.1:8811/mcp`, matching Codex/Hermes and exposing Docker-catalog tools without spawning duplicate stdio containers per Claude session.
- `gitlab` — direct local GitLab MCP HTTP service on `http://127.0.0.1:8812/mcp`, kept outside Docker Gateway because the zereight server has the MR/diff tools this workflow expects.
- `workflow` — local Workflow MCP on `http://127.0.0.1:8813/mcp`, used for bucket classification, Obsidian context discovery, delegation hints, and finish checklists.

### Claude Code plugins

Plugins come from two marketplaces, both registered under `extraKnownMarketplaces` in `settings.json` and enabled via `enabledPlugins`. Claude Code installs them on first run after the settings are read.

- [`anthropics/claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) — enables:
  - [`superpowers`](https://github.com/obra/superpowers) — the skills library this workflow treats as a reusable toolbox (brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion, requesting-code-review, receiving-code-review, finishing-a-development-branch).
  - `remember` — session-boundary state.
  - `claude-md-management` — auditing project-level AGENTS.md files.
- [`Gentleman-Programming/engram`](https://github.com/Gentleman-Programming/engram) — enables:
  - `engram` — persistent memory plugin. Registers the `engram` MCP server and the `mem_*` tool suite (`mem_save`, `mem_search`, `mem_context`, `mem_session_summary`, …). Requires the `engram` binary to be installed via Homebrew (see above). A SessionStart protocol makes saves proactive on decisions, bug fixes, and conventions.

## Token optimization (RTK)

**RTK (Rust Token Killer)** is a CLI proxy that filters verbose output from common dev tools (git, docker, npm, etc.) before it enters the context window, cutting 60–90% of tokens on read-heavy operations. A `PreToolUse` Bash hook (`rtk hook claude`) in `settings.json` transparently rewrites invocations — `git status` runs as `rtk git status` with no extra tokens spent on the rewrite itself. Meta commands (`rtk gain`, `rtk discover`) stay explicit. `RTK.md` holds the command reference and is imported into `CLAUDE.md` via `@RTK.md`.

RTK is optional — remove the `PreToolUse` entry in `settings.json` and the `@RTK.md` line at the bottom of `CLAUDE.md` to disable.

## Auto-sync

A `Stop` hook runs `auto-sync.sh` after each Claude turn. If any tracked file in `~/.claude/` has changed, it commits (`auto: sync YYYY-MM-DD HH:MM`) and pushes asynchronously. Failed pushes stay local and retry on the next successful turn. Session data, history, and caches are never staged (see `.gitignore`).

## Credits & inspirations

This workflow is a synthesis of ideas from people who published their own reasoning about how to make LLM-assisted development work well:

- **[azalio/map-framework](https://github.com/azalio/map-framework)** — the tiered-workflow idea (different entry points for small changes vs features vs debug vs TDD) comes directly from MAP. MAP goes further with multi-agent orchestration and persistent per-branch artifacts, which this repo deliberately doesn't adopt — the goal here is minimum viable structure, not maximum. Worth reading if you want the heavier version.
- **[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)** — the four meta-skills (think-before-coding, simplicity-first, surgical-changes, goal-driven-execution) are direct adaptations of the four principles in that repo. Those principles diagnose the core LLM failure modes better than most of what's been written on the topic.
- **[karpathy/llm-council CLAUDE.md](https://github.com/karpathy/llm-council/blob/master/CLAUDE.md)** — informed the split between a short, philosophical global `CLAUDE.md` and a detailed, gotcha-heavy project-level `AGENTS.md`. Read it for a good example of project-specific preventive specification.
- **[obra/superpowers](https://github.com/obra/superpowers)** and the Anthropic plugin ecosystem — the skills library this workflow reuses. The skills themselves are solid; what this repo changes is the *mandate* on top (we drop the one-size-fits-all 10-step flow).
- **[Model Context Protocol](https://modelcontextprotocol.io/)** and the [MCP reference servers](https://github.com/modelcontextprotocol/servers) — the standard that makes external tooling pluggable.

## Caveats

- **Paths are machine-local.** `settings.json`, `auto-sync.sh`, and a few other files contain absolute paths under `/Users/filipp.vysokov/`. If you fork, either edit them or set up your own home directory to match.
- **Auto-sync pushes without review.** The `Stop` hook commits and pushes every tracked change in `~/.claude/` after each Claude turn. A buggy hook or an edit Claude made that you didn't notice can land on your remote before you see it. For a personal config this is fine; if you publish a fork, consider disabling the `Stop` hook (`settings.json` → `hooks.Stop`) and committing manually.
- **Opinionated.** The taxonomy reflects how *I* work (mostly DevOps/infra, occasional Go/Python app code, frequent debug). Your buckets may differ. Edit `CLAUDE.md` and `skills/classify-task/SKILL.md` to match your reality.
- **Free to use for anyone, everywhere.** Reuse, fork, or adapt any part of this repo — no restrictions. Suggestions and contributions via issues are welcomed.

## Contributing

This is a personal workflow, but issues and discussion are welcome — especially if you find a classification rule that's wrong, a skill that contradicts itself, or a setup step that isn't documented clearly enough.
