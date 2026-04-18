#!/usr/bin/env zsh
set -euo pipefail

# launchd skips /etc/zprofile — run path_helper ourselves so /usr/local/bin
# (where Docker Desktop lives) is on PATH before we spawn docker-based MCPs.
[ -x /usr/libexec/path_helper ] && eval "$(/usr/libexec/path_helper -s)"

# Pull in OBSIDIAN_API_KEY, etc.
[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"

ROOT="$HOME/.claude/scheduled-tasks/weekly-knowledge-lint"
LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"

cd "$ROOT"

# Strip YAML frontmatter (---...--- at top) so claude doesn't parse it as a CLI option
PROMPT="$(awk 'BEGIN{f=0} /^---$/ {if(f<2){f++; next}} f>=2 {print}' "$ROOT/SKILL.md")"

printf '%s' "$PROMPT" | /Users/filipp.vysokov/.local/bin/claude \
  -p \
  --output-format text \
  --dangerously-skip-permissions \
  --model claude-sonnet-4-6

# Deterministic metrics sidecar — produces Daily/Lint/{TODAY}-metrics.md
python3 "$ROOT/metrics.py" 2>&1 || true

# Commit and push the log.md entry in the Knowledge/ repo, if dirty.
# Failures here must not break the run.
KN="$HOME/Obsidian/Work/Knowledge"
if [ -d "$KN/.git" ] && [ -n "$(git -C "$KN" status --porcelain 2>/dev/null)" ]; then
  git -C "$KN" add log.md 2>/dev/null || true
  git -C "$KN" commit -m "log: weekly lint $(date +%F)" 2>/dev/null || true
  git -C "$KN" push origin main 2>/dev/null || true
fi
