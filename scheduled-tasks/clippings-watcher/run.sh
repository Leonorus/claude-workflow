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
# Cap API cost per fire. Remaining clippings picked up on the next event.
MAX_PER_RUN="${CLIPPINGS_MAX_PER_RUN:-20}"

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

# Diff Clippings/ against state. Output lines are `<mtime>\t<basename>`.
PENDING="$(python3 "$ROOT/state.py" scan "$CLIPPINGS" "$STATE_FILE")"
if [ -z "$PENDING" ]; then
  echo "[$(date -Iseconds)] no new/modified clippings"
  exit 0
fi

TODAY="$(date +%F)"
SKILL_PROMPT="$(awk 'BEGIN{f=0} /^---$/ {if(f<2){f++; next}} f>=2 {print}' "$ROOT/SKILL.md")"

# One ingest call per clipping — keeps SKILL.md's "one clipping per run" invariant.
count=0
while IFS=$'\t' read -r mtime clipping; do
  [ -z "$clipping" ] && continue
  if [ "$count" -ge "$MAX_PER_RUN" ]; then
    echo "[$(date -Iseconds)] hit MAX_PER_RUN=$MAX_PER_RUN, deferring remainder to next fire"
    break
  fi
  count=$((count + 1))

  echo "[$(date -Iseconds)] ingesting ($count/$MAX_PER_RUN): $clipping"

  FULL_PROMPT="$SKILL_PROMPT

## This run's inputs
- TODAY = $TODAY
- CLIPPING = Clippings/$clipping
"
  # Branch on exit code: mark-success only on clean exit, mark-failure otherwise.
  # `|| true` on each state.py call so a single bad mark doesn't abort the batch.
  if printf '%s' "$FULL_PROMPT" | /Users/filipp.vysokov/.local/bin/claude \
      -p \
      --output-format text \
      --dangerously-skip-permissions \
      --model claude-sonnet-4-6; then
    python3 "$ROOT/state.py" mark-success "$STATE_FILE" "$mtime" "$clipping" \
      || echo "[$(date -Iseconds)] WARN state.py mark-success failed for $clipping"
  else
    rc=$?
    echo "[$(date -Iseconds)] ERROR ingesting $clipping (exit $rc) — will retry on next fire"
    python3 "$ROOT/state.py" mark-failure "$STATE_FILE" "$clipping" \
      || echo "[$(date -Iseconds)] WARN state.py mark-failure failed for $clipping"
  fi
done <<< "$PENDING"
