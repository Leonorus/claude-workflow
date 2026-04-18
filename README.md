# claude-workflow

A focused, context-aware workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Instead of forcing one heavy process onto every task, it classifies requests into buckets (trivia / light-ops / heavy-ops / go-python-app / go-python-script / debug / research) and applies weight proportional to what the task actually needs. Light tasks can **escalate to heavy mid-flight** when scope turns out bigger than stated. Karpathy-style meta-principles (think before coding, simplicity, surgical changes, goal-driven execution) run across all of them.

Plans and research live in an Obsidian vault outside any repo, treated as a **cross-project knowledge library** — patterns that repeat across repos get promoted to `Knowledge/<topic>.md` with cross-links. Architecture review and project-doc updates are first-class steps of the workflow, not afterthoughts.

## Why this exists

The default "install every plugin, run every gate on every task" setup produces two failure modes:

1. **Mandate mismatch.** A one-line typo and a 2000-line feature get the same 10-step checklist. So the checklist gets ignored.
2. **Competing authorities.** Five plugins plus a long `CLAUDE.md` plus SessionStart hooks all inject overlapping workflow rules. The agent picks the path of least resistance — often none of them.

This repo is the minimum-viable reset: a short `CLAUDE.md` with priority order and a task taxonomy, seven focused skills, and the specific MCP servers actually in use. Nothing that isn't earning its keep.

## What's in the repo

```
.
├── CLAUDE.md                    User-level preferences, 4 principles, MCP priority (taxonomy lives in classify-task skill)
├── RTK.md                       RTK (Rust Token Killer) reference — imported into CLAUDE.md via `@RTK.md`
├── settings.json                Plugin list, hooks (ansible-lint, terraform-fmt, auto-sync, obsidian-index, rtk)
├── mcp.json                     Docker-based MCP servers
├── statusline-command.sh        Custom status line (cwd, branch, context %, rate-limit %)
├── auto-sync.sh                 Stop-hook: commits and pushes tracked changes after each turn
├── hooks/
│   └── obsidian-index.sh        SessionStart-hook: emits ~/Obsidian/Work/ note index (paths + tags)
├── skills/
│   ├── classify-task/           Runs first on every request, picks the bucket
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

## Task taxonomy (the core idea)

| Bucket | Trigger signals | Weight |
|---|---|---|
| **Trivia** | typo, one-char rename, single-line config tweak, obvious doc fix | Just do it. No workflow. |
| **Light Ops** | Ansible/Terraform/k8s/CI/Docker: single file, <~50 diff lines, no prod-boundary touch, no new role/module/stack | Edit → lint → (dry-run only if touching prod vars/state) → commit → offer MR. No brainstorm, no arch review. |
| **Heavy Ops** | Ops change that is multi-file, touches prod boundary, introduces a new role/module/stack, is an architectural shift, or repeats across 2+ repos | Deep-dive: brainstorm → Obsidian check (`Knowledge/` + `Projects/`) → writing-plans → implement → lint → **mandatory dry-run gate** → arch review → apply → commit → MR → docs → Obsidian note. |
| **Go / Python app code** | real module (`go.mod` / `pyproject.toml`, tests dir present) | Full app pipeline: brainstorm → plan → **TDD** → code review → arch review → verify → doc update. |
| **Go / Python script** | single-file, <~100 lines, glue/automation | Short plan if non-trivial. No TDD. Arch review if not one-off. Doc update. |
| **Debug** | bug report, test failure, stack trace, "why is X broken" | `systematic-debugging`: hypothesis → minimal repro → instrument → fix → verify. No speculative fixes. |
| **Research** | "how does X work", "compare A vs B" — no bug, just learning | Read, investigate. Cross-project topic → `Knowledge/<topic>.md`; repo-specific → `Projects/<repo>/…`. No workflow weight. |
| **Ambiguous** | two buckets fit, or scope unclear | **Ask the user** before proceeding. |

The `classify-task` skill is invoked first on every request and picks the bucket out loud. It also defines **escalation rules** (a Light Ops fix pauses and offers promotion to Heavy Ops when the same pattern exists in 2+ repos, when the diff grows past ~50 lines, or when a one-line change turns out to patch around a deeper design issue) and threads **insights** — better approach, best-practice drift, simplification, cross-repo unification — into every non-trivia step boundary.

## Subagent fan-out (Heavy Ops / app code)

**Rule: fan out any step that reads without writing, join in main.** Context isolation sharpens precision on big tasks — but only when the fan-out targets are genuinely independent.

- **Fan out** (parallel subagents via `superpowers:dispatching-parallel-agents`): Obsidian `Projects/<repo>/` + `Knowledge/` searches, `context7` / `fetch` docs lookups, inventory scans ("all call sites of X", "every role implementing pattern Y"), per-file lint on independent modules, architecture review (already a subagent by design).
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
- **`Knowledge/<topic>.md`** — abstract, reusable patterns. **Own public git repo** (`Leonorus/knowlege` on GitHub), portable across jobs. Sanitized: no hostnames, internal URLs, tickets, employee names.
- **`Organization/<topic>.md`** — org-specific architecture and conventions. Local-only.

Each synthesis layer has an `index.md` (content catalog) and a `log.md` (append-only ingest/query/lint record).

**Scratch:** `Daily/YYYY-MM-DD.md` — daily notes; also where scheduled-task reports land.

**Ingest.** Two paths, same shape: (a) push from `Projects/` at end of task, (b) pull from `Clippings/` on demand. Both offer to propagate into `Knowledge/` and/or `Organization/`, update the target layer's `index.md`, and append to `log.md`. The `architecture-review` skill flags promotion candidates during its post-implementation pass.

**Search before acting.** Before implementing an Ops/Infra or Debug approach, Claude searches `Projects/<current-repo>/`, `Knowledge/`, and `Organization/` — the same problem may already be solved in another repo, a general pattern, or an org-specific decision.

**Lint.** Weekly (via `scheduled-tasks/weekly-knowledge-lint`) or on-demand: contradictions, orphan pages, missing cross-refs, ghost concepts, un-ingested clippings, and sanitization violations in `Knowledge/`.

At the end of non-trivia tasks, Claude asks "Take a note for this?" with a one-line summary + target path. On yes, the note is written automatically — no draft-review round-trip. Trivial tasks and duplicates are skipped without asking.

## Installation

```bash
# 1. Back up your current ~/.claude/ (important!)
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# 2. Clone this repo as your new ~/.claude/
git clone git@github.com:Leonorus/claude-workflow.git ~/.claude

# 3. Restart Claude Code so settings.json and mcp.json are re-read
```

If you already have customizations you want to keep, clone into a scratch directory and merge by hand.

### Post-install one-time setup

1. **Obsidian vault.** Create `~/Obsidian/Work/` with `Clippings/`, `Projects/`, `Knowledge/`, `Organization/`, and `Daily/` subdirectories. Open the folder as a vault in the Obsidian desktop app. For the `Knowledge/` layer, clone the public knowledge repo into it: `git clone git@github.com:Leonorus/knowlege.git ~/Obsidian/Work/Knowledge` (or your own fork).
2. **Obsidian Local REST API plugin** (required by the `mcp/obsidian` Docker image). In Obsidian: Settings → Community plugins → Browse → install **Local REST API** → enable → copy its API key.
3. **Export `OBSIDIAN_API_KEY`** in your shell env so the Docker container can pick it up. E.g. add to `~/.zshrc`:
   ```sh
   export OBSIDIAN_API_KEY='...'
   ```
4. **Pull the MCP Docker images** once so cold starts are fast:
   ```sh
   docker pull mcp/obsidian mcp/fetch mcp/sequentialthinking mcp/context7
   docker pull zereight050/gitlab-mcp
   ```
5. **(Optional) Edit paths in `settings.json`** if your home directory isn't `/Users/filipp.vysokov`. Look for absolute paths in the `statusLine` and `Stop` hook entries.
6. **(Optional) Enable scheduled tasks.** Each job under `scheduled-tasks/` ships a macOS launchd plist next to its `run.sh`. To activate:
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
- **[Docker](https://www.docker.com/)** — all MCP servers run as Docker containers.
- **[Obsidian](https://obsidian.md/)** — required for plans/notes routing and the Obsidian MCP.
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

### MCP servers (all Docker-based)

- [`mcp/sequentialthinking`](https://hub.docker.com/r/mcp/sequentialthinking) — complex multi-step reasoning.
- [`mcp/context7`](https://hub.docker.com/r/mcp/context7) — up-to-date docs for unfamiliar libraries (requires `CONTEXT7_API_KEY`).
- [`mcp/obsidian`](https://hub.docker.com/r/mcp/obsidian) — reads/writes the Obsidian vault. Source: [MarkusPfundstein/mcp-obsidian](https://github.com/MarkusPfundstein/mcp-obsidian).
- [`mcp/fetch`](https://hub.docker.com/r/mcp/fetch) — generic URL fetcher with markdown extraction. Source: [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers).
- [`zereight050/gitlab-mcp`](https://hub.docker.com/r/zereight050/gitlab-mcp) — GitLab ops (requires `GITLAB_PERSONAL_ACCESS_TOKEN`, `GITLAB_API_URL`).

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
- **Opinionated.** The taxonomy reflects how *I* work (mostly DevOps/infra, occasional Go/Python app code, frequent debug). Your buckets may differ. Edit `CLAUDE.md` and `skills/classify-task/SKILL.md` to match your reality.
- **Free to use for anyone, everywhere.** Reuse, fork, or adapt any part of this repo — no restrictions. Suggestions and contributions via issues are welcomed.

## Contributing

This is a personal workflow, but issues and discussion are welcome — especially if you find a classification rule that's wrong, a skill that contradicts itself, or a setup step that isn't documented clearly enough.
