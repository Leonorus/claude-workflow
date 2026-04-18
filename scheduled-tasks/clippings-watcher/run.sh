#!/usr/bin/env zsh
set -euo pipefail

# launchd skips /etc/zprofile — run path_helper so /usr/local/bin etc. are on PATH.
[ -x /usr/libexec/path_helper ] && eval "$(/usr/libexec/path_helper -s)"

# Pull in OBSIDIAN_API_KEY, etc.
[ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"

ROOT="$HOME/.claude/scheduled-tasks/clippings-watcher"
LOG_DIR="$ROOT/logs"
STATE_FILE="$ROOT/state.json"
CLIPPINGS="$HOME/Obsidian/Work/Clippings"
LOCK="$ROOT/.run.lock"

mkdir -p "$LOG_DIR"
cd "$ROOT"

# Atomic lock via mkdir — prevents overlapping runs when launchd fires rapidly.
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "[$(date -Iseconds)] another run in progress, exiting"
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null || true' EXIT

# Nothing to do if Clippings/ doesn't exist.
if [ ! -d "$CLIPPINGS" ]; then
  echo "[$(date -Iseconds)] Clippings/ does not exist, exiting"
  exit 0
fi

# Diff Clippings/ against state.
PENDING="$(python3 "$ROOT/state.py" scan "$CLIPPINGS" "$STATE_FILE")"
if [ -z "$PENDING" ]; then
  echo "[$(date -Iseconds)] no new/modified clippings"
  exit 0
fi

TODAY="$(date +%F)"
SKILL_PROMPT="$(awk 'BEGIN{f=0} /^---$/ {if(f<2){f++; next}} f>=2 {print}' "$ROOT/SKILL.md")"

# One ingest call per clipping — keeps SKILL.md's "one clipping per run" invariant.
while IFS= read -r clipping; do
  [ -z "$clipping" ] && continue
  echo "[$(date -Iseconds)] ingesting: $clipping"

  FULL_PROMPT="$SKILL_PROMPT

## This run's inputs
- TODAY = $TODAY
- CLIPPING = Clippings/$clipping
"
  printf '%s' "$FULL_PROMPT" | /Users/filipp.vysokov/.local/bin/claude \
    -p \
    --output-format text \
    --dangerously-skip-permissions \
    --model claude-sonnet-4-6 \
    || echo "[$(date -Iseconds)] ERROR ingesting $clipping"

  # Mark seen regardless — don't retry failed clippings every fire.
  python3 "$ROOT/state.py" mark "$STATE_FILE" "$CLIPPINGS" "$clipping"
done <<< "$PENDING"
