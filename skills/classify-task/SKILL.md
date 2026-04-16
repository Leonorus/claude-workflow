---
name: classify-task
description: Use at the very start of any user request, before invoking other skills or writing any code. Classifies the request into one of the workflow buckets (trivia, ops/infra, go-python-app, go-python-script, debug, research, ambiguous) and applies the matching weight. Asks the user if classification is uncertain.
---

# Classify task

First move on any request. Decides how much process to apply, and threads the user's preference for insights into every step. Without this, you default to either "heavy workflow on everything" (wasteful) or "no structure" (chaotic).

## The buckets

| Bucket | Signals | Weight applied |
|---|---|---|
| **Trivia** | typo, one-char rename, single-line config tweak, obvious doc fix | Just do it. No brainstorm, no plan, no arch review, no doc update. |
| **Light Ops** | Ansible/Terraform/k8s/CI/Docker change that is: single file, <~50 diff lines, no prod-boundary touch, no new role/module/stack, no architectural shift | Edit → lint → (dry-run only if touching prod vars/state) → commit → offer MR. No brainstorm, no arch review. Surface insights if noticed. |
| **Heavy Ops** | Ops change with any of: multi-file, prod-boundary touch (prod vars, live cluster, secrets, network/security rules), new role/module/stack, architectural shift, or same pattern exists in 2+ repos | Deep-dive: brainstorm → Obsidian check (`Knowledge/` + `Projects/`) → writing-plans → implement → lint/validate → **mandatory dry-run gate** → architecture-review → apply → commit → MR → update-project-docs → propose Obsidian note. |
| **Go / Python app code** | project has `go.mod` or `pyproject.toml`, has `tests/` or `_test.go`, multiple packages/modules | Full app pipeline: brainstorm → writing-plans → **TDD** (red-green-refactor) → requesting-code-review → architecture-review → verification-before-completion → update-project-docs. |
| **Go / Python script** | single file, <~100 lines, glue/automation, no tests dir, run-once or cron | Short plan if non-trivial. No TDD — manual smoke test. Arch review if it's not one-off. update-project-docs. |
| **Debug** | bug report, test failure, stack trace provided, "why is X broken", unexpected behavior | `systematic-debugging`: hypothesis → minimal repro → instrument → targeted fix → verify. No speculative fixes. If a fix ships: arch-review + verify + update-project-docs. Investigation-only: findings go to Obsidian (`Knowledge/` if reusable, else `Projects/<repo>/`). |
| **Research / Exploration** | "how does X work", "what's in this repo", "compare A vs B" — no bug, no code change | Read, investigate, report. Write findings to `Knowledge/<topic>.md` if the topic is cross-project, else `Projects/<repo>/<date>-<slug>.md`. No workflow weight. |
| **Ambiguous** | 2+ buckets fit, or scope is unclear | **Ask the user** which bucket + scope. Do not guess. |

## Procedure

1. Read the user's message end-to-end, including any pasted stack traces, file paths, or ticket references.
2. Pick the bucket. If none fits cleanly, pick **Ambiguous** and ask.
3. State the classification in one short sentence ("Treating this as Light Ops — edit, lint, commit, offer MR. No dry-run needed since it's not touching prod."). Skip the explicit statement for **Trivia** — just do it.
4. Apply the weight. Invoke the skills named in the bucket row, in order.

## Escalation — Light Ops → Heavy Ops (and similar promotions)

A light fix can turn out to be a hard task. If during Light Ops you notice **any** of:

- The same pattern exists in 2+ repos (unification opportunity).
- The fix patches around a deeper design issue (symptom vs cause).
- The change would break an implicit contract (role interface, module boundary, CI assumption).
- The user's follow-up reveals wider scope than stated.
- The diff is growing beyond ~50 lines or spreading to multiple files.

**Pause.** Announce: "This is looking like Heavy Ops because <specific reason>. I suggest we switch to the deep-dive flow: brainstorm → Obsidian check → plan → implement → dry-run → arch-review → apply. OK to proceed with the full pipeline, or do you want to stay on the light path and file the deeper concern separately?" Wait for the user's call.

Similar promotion rules apply: **Debug → Heavy Ops** (bug turns out to be design problem), **Trivia → Light Ops** (one-line change turns out to touch prod), **Light Ops → Research** (the user actually wants to understand first, not fix).

## Insights — woven into every non-trivia bucket

The user values insights over pure execution. At each natural step boundary (after classification, after Obsidian check, after implementation, before dry-run, at end of task), surface any of:

- **Better approach** you noticed while reading the code ("This role uses a loop-with-when pattern; native Ansible `when + with_items` would be simpler here.").
- **Best-practice drift** ("The Terraform module uses `count` where `for_each` would be safer against reorderings.").
- **Simplification** ("Three of these conditionals collapse to one.").
- **Cross-repo unification** ("This NGINX config pattern also lives in `infra-edge/` — worth promoting to `Knowledge/nginx-tls-offload.md`?").

Format: one short paragraph per insight. What matters is clarity. Do **not** implement insights silently — propose, wait for direction. Do not list insights the user would already know; only what would genuinely inform their decision.

## Cross-cutting (all buckets except Trivia and pure Research)

- After meaningful code/config change, invoke `update-project-docs`.
- Always-on meta-principles: `think-before-coding`, `simplicity-first`, `surgical-changes`, `goal-driven-execution`. These skills fire on their own when applicable; don't duplicate their checks here.
- Plans, debug findings, Knowledge entries → Obsidian (`mcp__obsidian__*` tools), not in-repo.
- Dry-run gate for Heavy Ops is blocking. Never apply without user OK.

## Anti-patterns

- Classifying silently when the bucket is non-trivia — the classification must be visible.
- Applying full app-code weight to a 20-line script because it's Python.
- Applying Trivia weight to something that touches production config.
- Skipping the "Ambiguous → ask" step and guessing.
- Running Light Ops pipeline past the diff-size/scope red flags without pausing to offer promotion.
- Surfacing insights as polite nothings ("this looks fine"). Say something concrete or nothing.
