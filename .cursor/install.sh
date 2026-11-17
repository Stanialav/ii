#!/usr/bin/env bash
# Idempotent check that the static site is present. No packages to install.
set -euo pipefail

python3 - <<'PY'
import pathlib
import sys

CABINET = "II-kabinet-buhgaltera-trial-v1.4.1.html"
LANDING = "index.html"
MARKER = "ИИ-кабинет бухгалтера"

def candidates():
    bases = []
    cwd = pathlib.Path.cwd()
    for base in (cwd, cwd.parent, cwd.parent.parent, pathlib.Path("/agent"), pathlib.Path("/workspace")):
        if base.is_dir():
            bases.append(base.resolve())
    seen = set()
    for base in bases:
        if base in seen:
            continue
        seen.add(base)
        yield base
        for pattern in ("*", "*/*", "*/*/*"):
            for path in base.glob(pattern):
                if path.is_dir():
                    yield path

found = None
for directory in candidates():
    cabinet = directory / CABINET
    landing = directory / LANDING
    if cabinet.is_file() and landing.is_file():
        found = directory
        break

if found is None:
    sys.exit("Could not find the II landing page and cabinet HTML")

cabinet = found / CABINET
if cabinet.stat().st_size < 100_000:
    sys.exit(f"cabinet file unexpectedly small: {cabinet}")

landing_text = (found / LANDING).read_text(encoding="utf-8", errors="replace")
if MARKER not in landing_text:
    sys.exit(f"landing page is missing the product title: {found / LANDING}")

print(f"site={found}")
PY
