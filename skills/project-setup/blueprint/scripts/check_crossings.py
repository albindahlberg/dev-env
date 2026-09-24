#!/usr/bin/env python3
"""Report cross-slice imports in a vertical feature-slice layout.

This is a STARTING POINT to adapt, not a finished tool. It assumes:

  <root>/<slice>/<responsibility>...        e.g. src/features/notes/service.py

and finds, for each slice, every reference to a *different* slice's name. It
then flags a reference that lands in a forbidden responsibility layer.

You will need to adjust:
  - IMPORT_PATTERNS       — the import syntax for your language(s)
  - --forbidden           — the responsibility layers no slice may import
  - how a "reference to slice X" is detected (the SLICE_REF template)

Wire the adapted script to an enforcement hook (a test, a CI step, a task
recipe) so the "Known crossings" list in ARCHITECTURE.md cannot drift
silently.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Lines that introduce a dependency. Extend for your stack.
IMPORT_PATTERNS = [
    re.compile(r"^\s*import\s+"),
    re.compile(r"^\s*from\s+"),
    re.compile(r"\brequire\("),
]

# Given a sibling slice name, a line "refers to" it if this matches.
def slice_ref(slice_name: str) -> re.Pattern[str]:
    return re.compile(rf"[./]{re.escape(slice_name)}[./]")


def source_files(root: Path) -> list[Path]:
    exts = {".py", ".js", ".jsx", ".ts", ".tsx", ".go", ".rb"}
    return [p for p in root.rglob("*") if p.suffix in exts and p.is_file()]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("root", type=Path, help="the slices root, e.g. src/features")
    ap.add_argument(
        "--forbidden",
        default="repository,router,interface,data",
        help="comma-separated responsibility layers no slice may import from another slice",
    )
    ap.add_argument("--list", action="store_true", help="print every crossing, not just violations")
    args = ap.parse_args()

    root: Path = args.root
    if not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    slices = sorted(p.name for p in root.iterdir() if p.is_dir() and not p.name.startswith((".", "_")))
    forbidden = {x.strip() for x in args.forbidden.split(",") if x.strip()}
    refs = {s: slice_ref(s) for s in slices}

    crossings: list[tuple[str, str, str, int, str]] = []  # (from_slice, to_slice, file, lineno, line)
    for f in source_files(root):
        try:
            rel = f.relative_to(root)
        except ValueError:
            continue
        from_slice = rel.parts[0]
        if from_slice not in slices:
            continue
        for lineno, line in enumerate(f.read_text(errors="replace").splitlines(), 1):
            if not any(p.search(line) for p in IMPORT_PATTERNS):
                continue
            for to_slice, pat in refs.items():
                if to_slice != from_slice and pat.search(line):
                    crossings.append((from_slice, to_slice, str(rel), lineno, line.strip()))

    violations = [c for c in crossings if any(f"/{layer}" in c[4] or f".{layer}" in c[4] for layer in forbidden)]

    if args.list:
        for from_s, to_s, path, ln, text in crossings:
            print(f"  {from_s} -> {to_s}  {path}:{ln}  {text}")
        print(f"\n{len(crossings)} crossing(s) total")

    if violations:
        print("\nFORBIDDEN-LAYER CROSSINGS:", file=sys.stderr)
        for from_s, to_s, path, ln, text in violations:
            print(f"  {from_s} -> {to_s}  {path}:{ln}  {text}", file=sys.stderr)
        print(f"\n{len(violations)} violation(s)", file=sys.stderr)
        return 1

    if not args.list:
        print(f"ok — {len(crossings)} crossing(s), no forbidden-layer imports")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
