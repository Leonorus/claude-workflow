#!/bin/sh
# Auto-commit and push tracked changes in ~/.claude/ to the workflow repo.
# Runs as a Stop hook after each Claude turn. Silent on success, best-effort on failure.

cd "$HOME/.claude" || exit 0
[ -d .git ] || exit 0

# Nothing to do if working tree is clean.
if [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

# Stage only the allowlisted files. If a path doesn't exist, git add skips it silently.
git add \
  .gitignore \
  README.md \
  CLAUDE.md \
  settings.json \
  mcp.json \
  statusline-command.sh \
  auto-sync.sh \
  skills \
  >/dev/null 2>&1

# If nothing actually got staged (e.g. all changes were in ignored files), exit.
if git diff --cached --quiet; then
  exit 0
fi

git commit -m "auto: sync $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || exit 0

# Push in background; do not block the session. Failures stay local until next successful push.
(git push --quiet >/dev/null 2>&1 &) 2>/dev/null

exit 0
