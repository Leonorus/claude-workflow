#!/usr/bin/env python3
"""Weekly vault metrics — emits a markdown report to Daily/Lint/{TODAY}-metrics.md."""

from __future__ import annotations

import os
import re
import sys
import warnings
from datetime import date, datetime, timedelta
from pathlib import Path

VAULT = Path.home() / "Obsidian" / "Work"
EXCLUDE_NAMES = {"index.md", "log.md", "README.md", ".gitkeep"}
STALE_THRESHOLD_DAYS = 365

TODAY = date.today()
PREV_MONDAY = TODAY - timedelta(days=TODAY.weekday() + 7)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def collect_md(root: Path, recursive: bool = False) -> list[Path]:
    """Return .md files under root, excluding EXCLUDE_NAMES."""
    if not root.exists():
        warnings.warn(f"Directory missing: {root}")
        return []
    glob = "**/*.md" if recursive else "*.md"
    return [
        p for p in root.glob(glob)
        if p.name not in EXCLUDE_NAMES and p.is_file()
    ]


def mean_age_days(files: list[Path]) -> str:
    if not files:
        return "n/a"
    now = datetime.now().timestamp()
    ages = [(now - p.stat().st_mtime) / 86400 for p in files]
    return f"{sum(ages) / len(ages):.1f}"


def parse_last_verified(path: Path) -> str | None:
    """Return last_verified value from YAML frontmatter, or None."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    m = re.search(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return None
    fm = m.group(1)
    v = re.search(r"^last_verified:\s*(.+)$", fm, re.MULTILINE)
    return v.group(1).strip() if v else None


def is_stale(last_verified: str | None) -> bool:
    if last_verified is None:
        return True
    for fmt in ("%Y-%m-%d", "%Y-%m-%dT%H:%M:%S", "%Y/%m/%d"):
        try:
            d = datetime.strptime(last_verified[:10], fmt[:len(fmt)])
            return (TODAY - d.date()).days > STALE_THRESHOLD_DAYS
        except ValueError:
            continue
    return True  # unparseable → stale


def find_linked_project_basenames(synthesis_files: list[Path]) -> set[str]:
    """Return basenames of Projects/ notes referenced in any synthesis page."""
    pattern = re.compile(r"\[\[Projects/[^\]]+\]\]")
    linked: set[str] = set()
    for f in synthesis_files:
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for m in pattern.finditer(text):
            inner = m.group()[2:-2]           # strip [[ ]]
            basename = Path(inner).name
            if basename.endswith(".md"):
                basename = basename[:-3]
            linked.add(basename)
    return linked


def parse_prior_metrics(path: Path) -> dict[str, int]:
    """Extract key numeric metrics from a prior report file."""
    vals: dict[str, int] = {}
    if not path.exists():
        return vals
    text = path.read_text(encoding="utf-8", errors="replace")
    for key, pattern in (
        ("knowledge", r"Knowledge/:\s*(\d+)"),
        ("organization", r"Organization/:\s*(\d+)"),
        ("projects", r"Projects/:\s*(\d+)"),
        ("stale", r"## Stale synthesis pages \((\d+)\)"),
    ):
        m = re.search(pattern, text)
        if m:
            vals[key] = int(m.group(1))
    return vals


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    # --- collect files ---
    k_files = collect_md(VAULT / "Knowledge")
    o_files = collect_md(VAULT / "Organization")
    p_files = collect_md(VAULT / "Projects", recursive=True)

    n_k, n_o, n_p = len(k_files), len(o_files), len(p_files)

    # --- promotion ratio ---
    synthesis_files = k_files + o_files
    linked_basenames = find_linked_project_basenames(synthesis_files)
    linked_count = sum(
        1 for f in p_files
        if f.stem in linked_basenames
    )
    pct = round(100 * linked_count / n_p) if n_p else 0

    # --- mean ages ---
    age_k = mean_age_days(k_files)
    age_o = mean_age_days(o_files)
    age_p = mean_age_days(p_files)

    # --- stale synthesis pages ---
    stale_entries: list[tuple[str, str]] = []
    for f in synthesis_files:
        lv = parse_last_verified(f)
        if is_stale(lv):
            rel = str(f.relative_to(VAULT))
            stale_entries.append((rel, lv if lv else "missing"))

    n_stale = len(stale_entries)

    # --- build report ---
    today_str = TODAY.strftime("%Y-%m-%d")
    stale_lines = "\n".join(
        f"- `{path}` — last_verified: {lv}" for path, lv in stale_entries
    ) or "_(none)_"

    report = f"""# Vault metrics — {today_str}

## Layer counts
- Knowledge/: {n_k}
- Organization/: {n_o}
- Projects/: {n_p}

## Promotion ratio
- Linked Projects notes: {linked_count}/{n_p} ({pct}%)

## Mean age of last edit (days)
- Knowledge/: {age_k}
- Organization/: {age_o}
- Projects/: {age_p}

## Stale synthesis pages ({n_stale})
{stale_lines}
"""

    # --- week-over-week deltas ---
    prev_str = PREV_MONDAY.strftime("%Y-%m-%d")
    prior_path = VAULT / "Daily" / "Lint" / f"{prev_str}-metrics.md"
    prior = parse_prior_metrics(prior_path)
    if prior:
        def delta(new: int, key: str) -> str:
            if key not in prior:
                return f"{new} (no prior)"
            d = new - prior[key]
            sign = "+" if d >= 0 else ""
            return f"{new} ({sign}{d})"

        report += f"""
## Week-over-week deltas (vs {prev_str})
- Knowledge/: {delta(n_k, 'knowledge')}
- Organization/: {delta(n_o, 'organization')}
- Projects/: {delta(n_p, 'projects')}
- Stale pages: {delta(n_stale, 'stale')}
"""

    # --- write output ---
    out_dir = VAULT / "Daily" / "Lint"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{today_str}-metrics.md"
    out_path.write_text(report, encoding="utf-8")
    print(f"Report written: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
