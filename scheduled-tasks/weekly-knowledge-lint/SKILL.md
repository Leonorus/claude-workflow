---
name: weekly-knowledge-lint
description: Weekly health check of Knowledge/ and Organization/ layers in the Obsidian vault
---

You are running headless on a weekly schedule. Do not ask questions. Use only Obsidian MCP tools and Read/Grep. Do not write to disk outside the Obsidian vault.

## Inputs (compute, do not ask)
- `TODAY` = current local date, format `YYYY-MM-DD`
- `VAULT` = Obsidian vault root (the MCP server is already configured)
- `LAYERS` = `["Knowledge", "Organization"]` (synthesis layers)
- `RAW_LAYERS` = `["Clippings", "Projects"]` (raw sources — read-only for this lint)

## Step 1 — inventory each layer

For each layer in `LAYERS`:
- List files via `mcp__docker_gateway__obsidian_list_files_in_dir` with `dirpath=<layer>/`
- Read `<layer>/index.md` and `<layer>/log.md`
- Read every content page (`*.md` other than `index.md`, `log.md`, `README.md`)

If a layer has zero content pages, record "empty layer" and skip analysis for it (still emit the heading with `_Empty layer, nothing to lint._`).

## Step 2 — analyze

For each layer, identify:

**A. Orphans** — content pages not listed in `index.md` AND not linked from any other content page in the same layer.

**B. Missing from index** — content pages that exist on disk but have no entry in `index.md`.

**C. Stale index entries** — entries in `index.md` pointing to pages that no longer exist.

**D. Contradictions** — direct contradictions between claims in different pages. Only flag high-confidence cases; quote the two conflicting sentences with their page names.

**E. Missing cross-refs** — concepts mentioned in page A that have their own page B in the same layer, but A does not link to B.

**F. Ghost concepts** — concepts/terms mentioned in 3+ pages that lack their own page.

**G. Abstract-pattern drift (Knowledge/ only)** — scan every `Knowledge/*.md` for employer-specific tokens that signal the page has drifted out of the abstract layer: internal hostnames and FQDNs, internal URLs, ticket IDs (project-prefixed like `PROJ-1234`), employee names/usernames, org codenames. Report `path:line` with the offending snippet — these pages should be rephrased generically or moved to `Organization/`.

**H. Stale pages** — list every `Knowledge/*.md` and `Organization/*.md` whose frontmatter `last_verified` is missing or older than 12 months from `TODAY`. Report `path` with the current `last_verified` value (or `missing`).

**I. Un-ingested clippings (global, reported once)** — list every file in `Clippings/` (recursive) that is NOT referenced by any page in `Knowledge/` or `Organization/`. Check for references by filename substring match (both bare `foo.md` and `[[Clippings/foo]]` forms). Report each un-ingested clipping with its relative path under `Clippings/`.

## Step 3 — emit report

Append to `Daily/Lint/{TODAY}.md` via `mcp__docker_gateway__obsidian_append_content` using this exact template. If a section has no items, write `_None_` on its own line — do NOT omit the heading.

```
## Knowledge Lint — {TODAY}

### Knowledge/

**Abstract-pattern drift:** {N}
- `{path}:{line}` — {snippet}

**Stale pages:** {N}
- `{path}` — last_verified: {value_or_missing}

**Orphans:** {N}
- `{path}` — {note}

**Missing from index:** {N}
- `{path}`

**Stale index entries:** {N}
- `{entry}` → `{target}` (missing)

**Contradictions:** {N}
- `{pageA}` §{X} vs `{pageB}` §{Y} — "{sentence A}" / "{sentence B}"

**Missing cross-refs:** {N}
- `{pageA}` → `{pageB}`

**Ghost concepts:** {N}
- `{concept}` — mentioned in [`{pageA}`, `{pageB}`, `{pageC}`]

### Organization/

(same structure as above, minus Abstract-pattern drift section)

### Clippings/

**Un-ingested clippings:** {N}
- `Clippings/{relpath}`
```

## Step 4 — log entries

Append one line to each layer's `log.md` via `mcp__docker_gateway__obsidian_append_content`:

```
## [{TODAY}] lint | {total_findings} findings ({N_drift} drift, {N_stale} stale, {N_orphans} orph, {N_contradictions} contra, {N_xref} xref, {N_ghost} ghost)
```

For `Organization/log.md`, omit the `drift` count.

## Rules

- Do NOT auto-fix. Only report.
- Never cite tangentially-related pages — only flag findings with direct keyword/content overlap.
- If a file is unreadable, note it in the report under a `**Errors:**` section and continue.
- Output nothing to the terminal beyond a single confirmation line of where the report was appended.
