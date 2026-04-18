#!/bin/sh
# Auto-commit and push tracked changes after each Claude turn.
# Targets: ~/.claude/ (workflow repo) and ~/Obsidian/Work/Knowledge/ (public knowledge repo).
# Silent on success, best-effort on failure.

sync_workflow() {
  cd "$HOME/.claude" || return 0
  [ -d .git ] || return 0

  if [ -z "$(git status --porcelain)" ]; then
    return 0
  fi

  # Stage only the allowlisted files. If a path doesn't exist, git add skips it silently.
  git add \
    .gitignore \
    README.md \
    CLAUDE.md \
    RTK.md \
    settings.json \
    mcp.json \
    statusline-command.sh \
    auto-sync.sh \
    install.sh \
    skills \
    hooks \
    agents \
    scheduled-tasks \
    >/dev/null 2>&1

  if git diff --cached --quiet; then
    return 0
  fi

  git commit -m "auto: sync $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || return 0
  (git push --quiet >/dev/null 2>&1 &) 2>/dev/null
}

sync_knowledge() {
  KN="$HOME/Obsidian/Work/Knowledge"
  [ -d "$KN/.git" ] || return 0

  if [ -z "$(git -C "$KN" status --porcelain)" ]; then
    return 0
  fi

  # Knowledge/ is a dedicated repo — its own .gitignore handles exclusions.
  git -C "$KN" add -A >/dev/null 2>&1

  if git -C "$KN" diff --cached --quiet; then
    return 0
  fi

  git -C "$KN" commit -m "auto: sync $(date '+%Y-%m-%d %H:%M')" >/dev/null 2>&1 || return 0
  (git -C "$KN" push --quiet >/dev/null 2>&1 &) 2>/dev/null
}

sync_workflow
sync_knowledge
exit 0
