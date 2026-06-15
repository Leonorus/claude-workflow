---
name: codex-workflow
description: Canonical human-readable policy for Filipp's proportional engineering workflow; Workflow MCP is the preferred structured front door when available, with this skill as fallback/source of truth. Loaded by name when Workflow MCP start_task returns it.
---

# Workflow (codex-workflow)

This is the canonical task-bucket workflow returned by Workflow MCP `start_task` as `codex-workflow`. It is the source of truth for task buckets. Apply only the amount of process the task deserves.

## Start-of-task Rule

Workflow: for substantial software/ops/debug/research/repo-maintenance, call mcp__workflow__start_task(prompt,cwd,repo) first; state/override bucket, load returned skills, follow contract/context/delegation/finish checklist. Use Workflow MCP and Obsidian via mcp__docker_gateway__obsidian_* before Obsidian claims and for workflow note reads/writes. Finish non-trivia with mcp__workflow__finish_checklist. Fallback: codex-workflow.

When Workflow MCP is exposed, treat that line as the first-move rule before planning, proposing an approach, or editing files. Pass the prompt plus `cwd`, `repo`, and `session_id` when known. Treat the returned packet as a structured checklist rather than unquestionable authority; override it when user correction or gathered evidence shows the bucket is wrong.

This skill remains the canonical human-readable policy. If Workflow MCP is unavailable, fails, is stale, or produces an obviously wrong classification, use this skill directly and state one visible sentence:

`Bucket: <bucket> — <why>; applying <matching workflow weight>.`

Skip this only for casual chat, simple factual answers, or clear follow-ups to an already-classified task.

## Classify First

For non-trivia work, state the bucket in one short sentence and run that flow:

| Bucket | Signals | Flow |
|---|---|---|
| Trivia | Typo, one-line obvious doc/config fix, mechanical rename | Just do it. No plan, no architecture review, no note. |
| Light Ops | Single-file Ansible/Terraform/k8s/CI/Docker, small diff, no prod boundary, no new role/module/stack | Inspect convention -> edit surgically -> run targeted lint/fmt/check -> summarize. |
| Heavy Ops | Multi-file ops, prod boundary, secrets/network/security, new role/module/stack, architectural shift, repeated pattern | Think before coding -> consult `codex-knowledge` -> plan -> implement -> lint/validate -> dry-run gate before apply -> review -> docs/note. |
| App Code | `go.mod`/`pyproject.toml`, tests present, multiple modules/packages | Define success -> add or run failing test first -> implement -> targeted tests -> review -> docs. |
| Script | Single-file Go/Python glue, run-once or cron, no app test harness | Short plan if non-trivial -> implement minimal script -> smoke-test safe input -> docs if reusable. |
| Debug | Bug report, failing test, stack trace, unexpected behavior | Reproduce -> hypothesize -> instrument/read -> fix the cause -> verify the exact failure is gone -> note findings if concrete. |
| Research | "How does X work", compare options, repo exploration, no code change | Read and report. Use Obsidian when this is Ops/Infra, Debug, architecture, or reusable research. |
| Repo-maintenance | Dependency bumps, CI cleanup, docs cleanup, tests, release metadata, repository hygiene, stale config, or convention maintenance | Inspect current convention -> split independent areas such as CI/deps/docs/tests/release -> use subagents where useful -> edit surgically -> run affected validation -> update docs/notes when conventions change. |
| Ambiguous | Multiple buckets fit or scope is unclear | Ask a concise clarifying question before edits. |

Escalate Light Ops to Heavy Ops if the diff grows beyond roughly 50 lines, spreads across files, touches prod/secrets/network, reveals a deeper design issue, or repeats across multiple repos.

## Bucket Contracts

Use these contracts after classification. They keep global agent instructions short while making each bucket's first move, context requirement, delegation posture, and finish condition explicit.

| Bucket | First move | Context / skills | Delegation default | Verification and finish |
|---|---|---|---|---|
| Trivia | Do the tiny change or answer directly. | No Obsidian, plan, or companion skill. | Never delegate. | Cheap check only if a file/command changed; no note. |
| Light Ops | Inspect nearby convention before editing. | Use repo-native lint/fmt/schema checks; no Obsidian unless design risk appears. | Usually direct; optionally one cheap reviewer/validator child. | Targeted lint/fmt/check, summarize. Escalate if scope or risk grows. |
| Heavy Ops | Name blast radius, assumptions, rollback/dry-run path. | Consult `codex-knowledge` / Obsidian before proposing approach; use sequential thinking when risk/tradeoffs are high. | Parallelize read-only discovery, risk review, and validation-plan review; parent keeps destructive actions. | Lint/validate/render/dry-run/smoke as applicable; docs and raw Obsidian note for concrete findings/fixes. |
| App Code | Define success criteria and existing test shape. | Inspect project conventions; use TDD/review skills when behavior changes or tests exist. | Use implementer/reviewer subagents for independent modules only. | Targeted tests first, broader checks as needed; update docs if API/workflow changed. |
| Script | Define input/output/exit-code, idempotency, and side effects. | Inspect runtime/schedule conventions; keep implementation minimal. | One implementer or reviewer for non-trivial scripts; avoid competing edits to same file. | Syntax check plus safe smoke test; for cron/launchd, verify schedule, locking/state, and logs. |
| Debug | Reproduce or observe the exact failure before fixing. | Consult Obsidian for prior incidents/patterns; use systematic debugging for unclear root cause. | Spawn an independent investigator when bug is unclear: repro/logs vs code-path/config. | Verify the exact failure is gone; note concrete root cause/fix unless duplicate/trivial. |
| Research | State the question, decision needed, and evidence bar. | Use Obsidian for Ops/Infra, Debug, architecture, or reusable research; use upstream docs/source when relevant. | Use 2-3 researchers when scope permits: upstream, local, Obsidian/org alternatives. | Report facts, assumptions, recommendation, confidence, risks, and next checks; no code changes. |
| Repo-maintenance | Check git status/diff and preserve unrelated user changes. | Inspect affected areas: CI, deps, docs, tests, release metadata, config conventions. | Split independent inspectors where useful. | Run affected checks, report unrelated findings separately, update docs/notes if conventions change. |
| Ambiguous | Ask one concise clarifying question, or proceed with an explicit low-risk assumption. | Do not load extra workflow beyond what is needed to clarify. | Do not delegate into unclear requirements. | No edits until scope is safe; reclassify after clarification. |

## Subagent Acceleration Policy

For substantial buckets, default to using available subagent or parallel-agent mechanisms when independent inspection, research, implementation, debugging-hypothesis, or review streams exist. Read-only delegation is free and explicitly user-authorized for code review, repo investigation, debugging, research, risk review, and validation planning; no separate confirmation is needed unless a child may mutate state or touch restricted external systems. This is a strong default, not blind fan-out: before doing substantial work directly, either spawn useful independent agents or state why delegation would slow the task down (single serial change, no independent workstream, tiny diff, destructive/interactive step, or missing context that only the parent has).

Bucket-specific defaults:

| Bucket | Subagent default |
|---|---|
| Trivia | No delegation. Do the tiny change directly. |
| Light Ops | Usually direct; read-only reviewer/validator delegation is free when useful. |
| Script | For non-trivial scripts, use one implementer or one reviewer; avoid competing edits to the same file. |
| Research | Use 2-3 parallel researchers when scope permits: upstream docs/source, local repo/context, and prior Obsidian/organization knowledge. |
| App Code | Read-only reviewers and test-shape inspectors are free; use implementer subagents for independent modules only. |
| Debug | Freely use at least one read-only investigator for unclear bugs: repro/logs vs code-path/config inspection. |
| Heavy Ops | Freely parallelize read-only discovery, risk review, and validation-plan review; keep destructive actions in the parent session. |
| Repo-maintenance | Freely split read-only CI, dependencies, docs, tests, and release metadata inspection where useful. |
| Ambiguous | Clarify first; do not spawn children into unclear requirements. |

In Claude Code, delegate via the `Agent` tool (subagent types such as `Explore`, `general-purpose`, `research`, `light-ops`); for 2+ independent streams use the `superpowers:dispatching-parallel-agents` skill. Extra tokens, context gathering, and independent agent passes are acceptable when they materially improve correctness, reasoning quality, speed to a verified result, or failure-rate reduction; do not under-spec context just to save tokens.

## Reasoning Guard Policy

For substantial buckets, prefer evidence-gated reasoning over token thrift. Use sequential thinking or an equivalent explicit reasoning scaffold when any guard trigger is present:

- Heavy Ops touching prod, network, secrets, permissions, data migration, or rollback-sensitive paths.
- Unclear Debug/root-cause work, repeated failed fixes, or bugs with multiple plausible causes.
- Architecture, migration, scaling, or performance decisions where tradeoffs matter.
- Risky app-code refactors, cross-module behavior changes, or user requests for higher confidence.

The reasoning guard should track:

- `mode`: debugging, architecture, performance, ops, research, app-code, or repo-maintenance.
- `evidence`: tool-backed refs such as file paths/line ranges, command output, CI/job IDs, fetched docs, Obsidian note paths, benchmark results, or deployment/dry-run output.
- `alternatives`: at least two options for architecture/Heavy Ops decisions and at least two falsifiable hypotheses for unclear Debug.
- `confidence`: confidence claims above 80 require tool-backed evidence plus a verification plan; otherwise lower the confidence or gather more evidence.
- `budget`: 2-3 thoughts for light analysis, 3-5 for standard debug/research, and 5-8 for high-risk architecture/Heavy Ops. Continue past the budget only when new evidence, a branch, or a contradiction is reducing risk.

Mode-specific stop/go checks:

- Debug: do not fix before reproducing or observing the exact failure and naming at least one falsifiable hypothesis.
- Heavy Ops: do not apply before naming blast radius, rollback/dry-run path, secret/network boundary, and validation.
- Architecture: do not recommend before comparing alternatives, tradeoffs, and the decision rule; emit a compact decision/ADR summary when a choice is made.
- Performance: do not claim improvement without a baseline, target metric, and measurement/benchmark command or a stated reason measurement is impossible.
- Research: distinguish fetched/source-backed facts from assumptions and cite only docs/notes actually read.

Persist only durable outcomes: compact project notes, skills, or memory entries that record decision, evidence, verification, and later outcome. Prefer decision/outcome records over raw thought traces.

## Workflow MCP and Obsidian Context

For Ops/Infra, Debug, architecture choices, and reusable research, use `mcp__workflow__start_task` candidate notes or `mcp__workflow__discover_context` when Workflow MCP is available, then read the directly relevant Obsidian notes via `mcp__docker_gateway__obsidian_*` before proposing an approach. Without Workflow MCP, consult `codex-knowledge` manually. Candidate paths are routing metadata, not citations; cite only notes actually read.

## Always-On Principles

- Think before coding: name the goal, load-bearing assumptions, unknowns, and tradeoffs before edits.
- Simplicity first: implement only what the current request needs; avoid speculative flags, helpers, abstractions, and "nice to have" extras.
- Surgical changes: touch only required lines plus direct wiring/tests; report unrelated issues instead of fixing them inline.
- Goal-driven execution: define "done" as verifiable criteria, run the smallest relevant check first, and only claim success with command evidence.

## Cross-Cutting Requirements

- For Ops/Infra, Debug, architecture choices, and reusable research, consult `codex-knowledge` before proposing an approach.
- After implementation, update affected project docs and `AGENTS.md` instructions when the change alters workflow, commands, architecture, or conventions.
- For Debug and Heavy Ops with meaningful operational findings, check the repo `AGENTS.md` during the finisher. If repo guidance is stale or missing because the task changed commands, architecture, safety rules, or conventions, rewrite it directly in the task session with normal diff review and verification. Weekly knowledge review only suggests `AGENTS.md` or workflow guidance changes; it does not perform these edits.
- For workflow note reads, writes, or updates, use `mcp__docker_gateway__obsidian_*` tools as the first note surface; avoid shell commands, raw filesystem access, redirection, heredocs, or Python scripts for vault notes unless those tools are unavailable, then state the fallback.
- Heavy Ops and Debug with a shipped fix or concrete findings should write a raw Obsidian note unless duplicate or trivial.
- Other non-trivia buckets should ask whether to take a note, with a one-line summary and target path.
- Use `Projects/<repo>/YYYY-MM-DD-<slug>.md` for raw notes.
- After creating or updating a raw project note, run targeted Obsidian discovery against `Projects/<repo>/`, `Knowledge/`, and `Organization/` to decide whether the new finding should be promoted, linked, or left raw.
- Promote to `Knowledge/` when the pattern plausibly applies at 5+ different employers; update the Knowledge page, `Knowledge/index.md`, and `Knowledge/log.md` in the same pass.
- Put internal hostnames, concrete service graphs, ticket IDs, employee names, org codenames, and company-specific runbooks in `Organization/`; update `Organization/index.md`/`log.md` when making synthesis-layer changes there.

## Runtime Adaptation (Claude Code)

- Delegate via the `Agent` tool and its subagent types; use `superpowers:dispatching-parallel-agents` for 2+ independent streams. Keep destructive/user-facing actions in the parent session.
- Do not use or invent Beads, `bd`, `template-bridge`, or mandatory task-tracker commands. Those tools are not currently available.
- Do not use git worktrees unless the user explicitly asks. Work directly in the current checkout.
- Use project-local `AGENTS.md` as the durable instruction surface. Do not create new `CLAUDE.md` files. If a repo has `CLAUDE.md`, migrate relevant project instructions into `AGENTS.md` when safe.
- For Claude Code / Claude API / Agent SDK questions, use the `claude-code-guide` agent and the `claude-api` skill against official sources.
- Prefer local tools and project conventions over generic workflow steps.
- Prefer RTK-prefixed shell commands when practical. For complex shell features that RTK cannot parse, use `rtk proxy <cmd>`.

## Review And Finish

Before final response:

- Check `git diff`/`git status` for unintended edits when working in a git repo.
- Run relevant verification: tests, lint, formatter, build, dry-run, syntax check, or smoke check.
- If verification could not run, state the exact blocker.
- For meaningful code/config changes, update affected docs or explain why none were affected.
