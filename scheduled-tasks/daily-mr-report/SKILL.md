---
name: daily-mr-report
description: Daily weekday report of DEVOPS/INFRADESK GitLab MRs, appended to the Obsidian daily note
---

You are running headless on a schedule. Do not ask questions. Use only the GitLab and
Obsidian MCP tools. Do not write to disk outside Obsidian.

## Inputs (compute, do not ask)
- `TODAY` = current local date, format `YYYY-MM-DD`
- `WINDOW_START` = `TODAY` minus 24h, ISO8601
- `PREFIXES` = `["DEVOPS", "INFRADESK"]`
- `ME` = `filipp.vysokov`

## Step 1 — collect MRs

For each prefix in `PREFIXES`, call `mcp__gitlab__list_merge_requests` twice:
1. `state=merged`, `updated_after=WINDOW_START`, `scope=all`, `search=<prefix>`
2. `state=opened`, `scope=all`, `search=<prefix>`

For each MR keep: `iid`, `web_url`, `project_path` (from `references.full` or
`web_url`), `title`, `author.username`, `created_at`, `merged_at`, `description`.

Deduplicate by `web_url`.

## Step 2 — per-MR summary (parallel subagents)

Dispatch one `Explore` subagent per MR. Batch in groups of 8 in a single message
(parallel). Subagent prompt — self-contained, no shared context:

```
You are summarizing a single GitLab MR for a daily report.
project_path: {project_path}
mr_iid: {iid}
title: {title}
author description: {description}

Call mcp__gitlab__list_merge_request_diffs with project_id={project_path} and
merge_request_iid={iid}. Read the diff. Truncate any single-file diff over 200
lines. Return ONE sentence (≤25 words) describing what the change does in plain
English. No preamble, no bullets, no code fences. If the diff is unavailable,
return the author description trimmed to 25 words. Never invent.
```

Store each result as `summary` keyed by MR `web_url`.

## Step 3 — render and append

Use `mcp__obsidian__obsidian_append_content` to append to
`Daily/{TODAY}.md` (vault path is the configured Obsidian vault root).

Append exactly this template — no extra prose, no context blocks, no last-7-days
section. If a section has no MRs, write `_None_` on its own line — do NOT omit
the heading.

```
## MR Report — {TODAY}

### Merged in last 24h

#### DEVOPS
| MR | Repo | Title | Summary | Author |
|---|---|---|---|---|
| [{iid}]({web_url}) | `{project_path}` | {title} | {summary} | {author}{me_marker} |

#### INFRADESK
| MR | Repo | Title | Summary | Author |
|---|---|---|---|---|
| [{iid}]({web_url}) | `{project_path}` | {title} | {summary} | {author}{me_marker} |

### Open MRs

#### DEVOPS
| MR | Repo | Title | Summary | Author | Age |
|---|---|---|---|---|---|
| [{iid}]({web_url}) | `{project_path}` | {title} | {summary} | {author}{me_marker} | {N}d{stale_marker} |

#### INFRADESK
| MR | Repo | Title | Summary | Author | Age |
|---|---|---|---|---|---|
| [{iid}]({web_url}) | `{project_path}` | {title} | {summary} | {author}{me_marker} | {N}d{stale_marker} |
```

Rules:
- `me_marker` = ` 👤` when `author == ME`, else empty.
- `stale_marker` = ` ⏳` when `age > 1 day`, else empty.
- Sort merged by `merged_at` desc; sort open by age desc.
- Never write to `~/.claude/scheduled-tasks/daily-mr-report/reports/` or `~/Projects/mrs/`.
- Output nothing to the terminal beyond a single confirmation line of where the
  report was appended.
