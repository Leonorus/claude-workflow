---
name: codex-knowledge
description: Use Filipp's Obsidian knowledge workflow from Codex. Trigger for Ops/Infra, Debug, Heavy Ops, architecture decisions, reusable research, end-of-task notes, knowledge promotion, clipping ingestion, or knowledge/organization linting involving ~/Obsidian/Work.
---

# Codex Knowledge

Use the Obsidian vault as a cross-project library, not a per-repo scratchpad.

## Vault Layout

Vault root: `~/Obsidian/Work/`.

- `Clippings/`: immutable external sources. Read and link; never edit, rename, or delete.
- `Projects/<repo>/YYYY-MM-DD-<slug>.md`: raw per-repo plans, debug notes, and findings.
- `Knowledge/<topic>.md`: abstract reusable patterns portable across employers. Own Git repo.
- `Organization/<topic>.md`: org-specific architecture, service graph, conventions, runbooks. Local only.
- `Daily/YYYY-MM-DD.md`: scratch and reports.

`Knowledge/` and `Organization/` each maintain `index.md` and `log.md`.

## Knowledge Pipeline

Treat each layer as a different durability and action surface:

- Raw project notes are evidence. They capture chronology, observations, plans, and findings, but they are not automatically reusable guidance.
- Project registers track unresolved or repeated issues, decisions, and risks that should survive across task sessions.
- `Organization/` stores org-specific synthesis: concrete service graphs, internal conventions, runbooks, hostnames, ticketed context, and private operational details.
- `Knowledge/` stores abstract reusable patterns that plausibly apply across 5+ employers.
- `AGENTS.md` stores execution guardrails only: commands, safety rules, conventions, and workflow constraints that should affect future agent behavior.

Weekly knowledge review may append safe `Knowledge/`, `Organization/`, and register updates, but it must not edit any `AGENTS.md` or user-wide workflow guidance. Weekly review only suggests those guardrail changes. Repo `AGENTS.md` analysis and rewrite belongs to the task session finisher when Debug or Heavy Ops work changed commands, architecture, safety rules, or conventions.

## Project Registers

Use registers when a finding is durable but not broad enough for synthesis:

- `Projects/<repo>/registers/problem-register.md` for unresolved or repeated problems.
- `Projects/<repo>/registers/decision-register.md` for durable repo-local decisions.
- `Projects/<repo>/registers/risk-register.md` for risks, mitigations, and review points.

Register entries are append-only and use stable identifiers:

```md
## PROB-YYYY-NNN short title

Status: Active | Mitigated | Fixed | Accepted | Deferred
Sources:
- [[Projects/<repo>/<note>]]
Current workaround:
Desired fix:
Verification:
Next action:
Last reviewed: YYYY-MM-DD
```

Decision entries use `DEC-YYYY-NNN`; risk entries use `RISK-YYYY-NNN`.

## Search Before Acting

For Ops/Infra, Debug, architecture choices, and reusable research:

1. Search `Projects/<current-repo>/`, `Knowledge/`, and `Organization/`.
2. Use direct keyword overlap: component names, hostnames, error strings, ticket IDs, module names.
3. Prefer `mcp__docker_gateway__obsidian_*` read/search/list tools when available. If not available, use filesystem reads under `~/Obsidian/Work/` and state the fallback before reading.
4. Cite only directly relevant notes. Do not cite tangential pages.

## End-Of-Task Notes

For non-trivia tasks:

- When `mcp__docker_gateway__obsidian_*` tools are available, use them as the note read/write surface; do not read, create, or update vault notes with shell commands, raw filesystem access, redirection, heredocs, or Python unless those tools are unavailable. If they are unavailable, state the fallback before filesystem access.
- Heavy Ops and Debug with a shipped fix or concrete findings: write a raw note automatically unless it is duplicate or trivial.
- Other non-trivia tasks: ask "Take a note for this?" with a one-line summary and target path.
- Use `Projects/<repo>/YYYY-MM-DD-<slug>.md` for raw notes.
- After creating or updating a raw project note, run targeted discovery across `Projects/<repo>/`, `Knowledge/`, and `Organization/` to decide whether the new finding should be promoted, linked, or left raw.
- Promote to `Knowledge/` only when there is a genuinely reusable pattern that plausibly applies at 5+ different employers; update the Knowledge page, `Knowledge/index.md`, and `Knowledge/log.md` in the same pass.
- Put organization-specific material in `Organization/` and update `Organization/index.md`/`log.md` when making synthesis-layer changes there.

## End-Of-Task Classification

For Heavy Ops and Debug finishers, classify any durable outcome before ending the task:

- raw note captured when the concrete finding/fix is non-trivial and not duplicate;
- register update for unresolved/repeated problems, durable repo-local decisions, or risks;
- `Knowledge/` or `Organization/` promotion when the evidence is mature enough for synthesis;
- `AGENTS.md` update when this session changed commands, architecture, safety rules, or conventions and the current repo guidance is stale or missing;
- `AGENTS.md` suggestion when the guardrail should be reviewed by a human or applies outside the current repo;
- no durable update when the work was trivial, duplicate, or too stale/speculative.

## Promotion Rules

Before writing to `Knowledge/`, apply the abstract-pattern test: the page should plausibly apply at 5+ different employers.

- Put generic practices, debug recipes, architectural patterns, and tool notes in `Knowledge/`.
- Put internal hostnames, concrete service graphs, ticket IDs, employee names, org codenames, and company-specific runbooks in `Organization/`.
- Use relative Obsidian links back to sources, for example `[[Projects/repo/2026-04-24-debug-x]]`.
- Update the target layer's `index.md` and append `## [YYYY-MM-DD] <op> | <title>` to `log.md`.

## Lint Workflow

When asked to lint knowledge or organization, scan for contradictions, stale `last_verified` over 12 months, orphan pages, missing cross-links, ghost concepts, un-ingested clippings, and sanitization violations in `Knowledge/`.

Report to `Daily/Lint/<today>.md` and metrics to `Daily/Lint/<today>-metrics.md`; act on fixes only after approval.
