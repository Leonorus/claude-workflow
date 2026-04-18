---
name: clippings-watcher
description: Auto-ingest a newly-added clipping from Clippings/ into the synthesis layers (Knowledge/ or Organization/). Fully automated — no human approval; gating lives in the refusal rules below.
---

You are running headless, triggered by a filesystem-watcher. A single clipping file has been added or modified in `Clippings/`. Your job is to ingest it into the synthesis layers (`Knowledge/` or `Organization/`) without asking questions.

## Inputs (passed by orchestrator, do not ask)
- `TODAY` = current local date, `YYYY-MM-DD`
- `CLIPPING` = the relative path under `Clippings/` of the file that changed (e.g. `Clippings/some-article.md`)

Read these before doing anything:
- The clipping itself: `mcp__obsidian__obsidian_get_file_contents` on `{CLIPPING}`
- `Knowledge/index.md` — to see existing abstract topics
- `Organization/index.md` — to see existing org-specific topics

## Step 1 — classify

Decide exactly ONE of:

**(a) Promote to `Knowledge/<topic>.md`** — requires ALL of:
  - Content is an abstract, portable pattern (architecture, practice, debug recipe, tool note).
  - Passes the **5+ employers test**: could plausibly apply to 5+ different employers.
  - Contains NO proper nouns that identify a specific employer: internal hostnames, internal FQDNs, internal URLs, ticket IDs (project-prefixed like `PROJ-1234`), employee names/usernames, org codenames.

**(b) Promote to `Organization/<topic>.md`** — when content is org-specific: internal architecture, service graph, conventions, runbooks, internal tooling. Proper nouns are allowed here.

**(c) Skip** — if the clipping is off-topic, marketing fluff, a duplicate of existing synthesis content with nothing new, or below the relevance floor (generic news, trivia, content that wouldn't help future-you on any task).

## Step 2 — act

### If (a) or (b):

Choose a `<topic>.md` slug:
- If an existing page in the target layer has direct topical overlap → **update that page** (add a new §, don't overwrite). Never create a second page for the same topic.
- Otherwise → create a new page.

Page must have frontmatter:
```yaml
---
tags: [knowledge, <topic>]   # or [organization, <topic>]
last_verified: {TODAY}
sources:
  - "[[Clippings/{CLIPPING_BASENAME}]]"
---
```

On update, append `{CLIPPING}` to the `sources:` list and refresh `last_verified: {TODAY}`.

Body must:
- Cite the clipping inline at least once via `[[Clippings/<basename>]]`.
- For `Knowledge/` pages: cross-link to related abstract topics with `[[<topic>]]`.
- For `Organization/` pages: cross-link up to related `[[Knowledge/<topic>]]` pages when the org-specific content is an instance of an abstract pattern.

Tools:
- Create: `mcp__obsidian__obsidian_append_content` (path creates if absent).
- Update: `mcp__obsidian__obsidian_patch_content` for targeted §-additions, or append_content for a new trailing §.

Update `<layer>/index.md`:
- Use `mcp__obsidian__obsidian_patch_content` to add the new page under its category (or create a category heading if none fits).
- One line: `- [[<topic>]] — <one-line description>`.

Append to `<layer>/log.md`:
```
## [{TODAY}] ingest | {topic} ← [[Clippings/{CLIPPING_BASENAME}]]
```

### If (c) — skip:

Append a single line to `Daily/{TODAY}.md` via `mcp__obsidian__obsidian_append_content`:
```
- **Clipping skipped**: `[[Clippings/{CLIPPING_BASENAME}]]` — <one-short-reason>
```
Do not touch the synthesis layers. Do not write to any log.md.

## Step 3 — confirmation

Output a single terminal line. Nothing else:
```
{decision} {target_or_reason} | clipping={CLIPPING}
```
Where `{decision}` is one of `KNOWLEDGE`, `ORGANIZATION`, `SKIP`.
Examples:
- `KNOWLEDGE drbd-linstor-split-brain-recovery.md (new) | clipping=Clippings/drbd-howto.md`
- `ORGANIZATION capi-helm-vs-cue.md (update §Decision) | clipping=Clippings/internal-post.md`
- `SKIP below-relevance-floor | clipping=Clippings/tech-news-roundup.md`

## Refusal rules (no asking, no exceptions)

1. **Never write to `Knowledge/` if you detect any proper noun that identifies an employer.** Divert to `Organization/` or skip.
2. **Never create a duplicate page.** If a topic already has a page, update it.
3. **Never overwrite existing content.** Always append or patch — never replace.
4. **Never modify the clipping itself.** `Clippings/` is immutable.
5. **Never write to `Projects/`.** That layer is for human/LLM-authored working notes, not ingests.
6. **If unreadable or malformed, skip (c) with reason `unreadable`.** Do not loop, do not retry.
7. **One clipping per run.** Do not ingest other files even if you notice them.
