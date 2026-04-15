#!/bin/sh
input=$(cat)

# ANSI color helpers
reset='\033[0m'
bold='\033[1m'
dim='\033[2m'

fg_blue='\033[34m'
fg_cyan='\033[36m'
fg_green='\033[32m'
fg_yellow='\033[33m'
fg_red='\033[31m'
fg_white='\033[37m'
fg_gray='\033[90m'

# Build a 10-block Unicode progress bar and pick a color based on percentage.
# Usage: make_bar <percentage_integer>
# Prints: COLOR▓▓▓▓░░░░░░RESET
make_bar() {
  pct="$1"
  filled=$(( pct / 10 ))
  empty=$(( 10 - filled ))

  if [ "$pct" -ge 80 ]; then
    bar_color="$fg_red"
  elif [ "$pct" -ge 50 ]; then
    bar_color="$fg_yellow"
  else
    bar_color="$fg_green"
  fi

  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}▓"
    i=$(( i + 1 ))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done

  printf '%b' "${bar_color}${bar}${reset}"
}

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

out=""

# Working directory — blue
if [ -n "$cwd" ]; then
  out="${fg_blue}${bold}${cwd}${reset}"
fi

# Git branch — cyan
if [ -n "$branch" ]; then
  out="${out}  ${fg_cyan}${branch}${reset}"
fi

# Context window usage — label in gray, bar + % colored by level
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    pct_color="$fg_red"
  elif [ "$used_int" -ge 50 ]; then
    pct_color="$fg_yellow"
  else
    pct_color="$fg_green"
  fi
  bar=$(make_bar "$used_int")
  out="${out}  ${fg_gray}ctx:${reset}${bar} ${pct_color}${used_int}%${reset}"
fi

# 5-hour rate limit — same treatment
if [ -n "$five_hour" ]; then
  five_int=$(printf '%.0f' "$five_hour")
  if [ "$five_int" -ge 80 ]; then
    pct_color="$fg_red"
  elif [ "$five_int" -ge 50 ]; then
    pct_color="$fg_yellow"
  else
    pct_color="$fg_green"
  fi
  bar=$(make_bar "$five_int")
  out="${out}  ${fg_gray}5h:${reset}${bar} ${pct_color}${five_int}%${reset}"
fi

printf '%b' "${out}"
