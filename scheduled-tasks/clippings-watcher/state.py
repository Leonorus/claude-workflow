#!/usr/bin/env python3
"""State management for clippings-watcher.

Usage:
  state.py scan <clippings-dir> <state-file>              # prints pending basenames, one per line
  state.py mark <state-file> <clippings-dir> <basename>   # marks basename as seen (records current mtime)
"""
import json
import os
import sys
from pathlib import Path


def load_state(path):
    if not os.path.exists(path):
        return {"seen": {}}
    with open(path) as f:
        return json.load(f)


def save_state(path, state):
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)


def cmd_scan(clippings_dir, state_file):
    state = load_state(state_file)
    seen = state.get("seen", {})
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
        if seen.get(entry.name) != mtime:
            print(entry.name)


def cmd_mark(state_file, clippings_dir, basename):
    state = load_state(state_file)
    state.setdefault("seen", {})
    path = Path(clippings_dir) / basename
    if path.exists():
        state["seen"][basename] = path.stat().st_mtime
    save_state(state_file, state)


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: state.py scan|mark ...")
    cmd = sys.argv[1]
    if cmd == "scan" and len(sys.argv) == 4:
        cmd_scan(sys.argv[2], sys.argv[3])
    elif cmd == "mark" and len(sys.argv) == 5:
        cmd_mark(sys.argv[2], sys.argv[3], sys.argv[4])
    else:
        sys.exit(f"bad args: {sys.argv}")


if __name__ == "__main__":
    main()
