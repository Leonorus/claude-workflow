#!/usr/bin/env python3
"""State management for clippings-watcher.

state.json shape:
  {
    "seen":     {"<basename>": <mtime float>, ...},  # successfully ingested
    "attempts": {"<basename>": <int>, ...}           # failed attempts not yet successful
  }
After MAX_ATTEMPTS failures, scan silently skips the file (logged to stderr) —
prevents permanent-failure loops. Clear state.json["attempts"][name] to retry.

Usage:
  state.py scan         <clippings-dir> <state-file>
      → stdout: one pending clipping per line, format `<mtime>\\t<basename>`
      → stderr: "skip (max-attempts=N): <basename>" for poison-pilled files

  state.py mark-success <state-file> <mtime> <basename>
      → records <basename> at <mtime> in `seen`; clears any `attempts` entry

  state.py mark-failure <state-file> <basename>
      → increments `attempts[<basename>]` by 1
"""
import json
import os
import sys
from pathlib import Path


MAX_ATTEMPTS = 3


def load_state(path):
    if not os.path.exists(path):
        return {"seen": {}, "attempts": {}}
    with open(path) as f:
        state = json.load(f)
    state.setdefault("seen", {})
    state.setdefault("attempts", {})
    return state


def save_state(path, state):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)


def cmd_scan(clippings_dir, state_file):
    state = load_state(state_file)
    seen = state["seen"]
    attempts = state["attempts"]
    clippings = Path(clippings_dir)
    if not clippings.exists():
        return
    for entry in sorted(clippings.iterdir()):
        if not entry.is_file():
            continue
        if entry.name.startswith("."):
            continue
        if not entry.name.endswith(".md"):
            continue
        mtime = entry.stat().st_mtime
        if seen.get(entry.name) == mtime:
            continue  # already ingested at this mtime
        if attempts.get(entry.name, 0) >= MAX_ATTEMPTS:
            print(f"skip (max-attempts={MAX_ATTEMPTS}): {entry.name}", file=sys.stderr)
            continue
        # Tab-separated so run.sh can parse with IFS=$'\t'.
        print(f"{mtime}\t{entry.name}")


def cmd_mark_success(state_file, mtime_str, basename):
    state = load_state(state_file)
    state["seen"][basename] = float(mtime_str)
    state["attempts"].pop(basename, None)
    save_state(state_file, state)


def cmd_mark_failure(state_file, basename):
    state = load_state(state_file)
    state["attempts"][basename] = state["attempts"].get(basename, 0) + 1
    save_state(state_file, state)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: state.py scan|mark-success|mark-failure ...")
    cmd = sys.argv[1]
    if cmd == "scan" and len(sys.argv) == 4:
        cmd_scan(sys.argv[2], sys.argv[3])
    elif cmd == "mark-success" and len(sys.argv) == 5:
        cmd_mark_success(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "mark-failure" and len(sys.argv) == 4:
        cmd_mark_failure(sys.argv[2], sys.argv[3])
    else:
        sys.exit(f"bad args: {sys.argv}")


if __name__ == "__main__":
    main()
