#!/usr/bin/env bash
# Serve the static II site. Safe to run again: if port 8000 is open, exit.
set -euo pipefail

PORT=8000

if python3 -c 'import socket,sys; s=socket.create_connection(("127.0.0.1", int(sys.argv[1])), 2); s.close()' "$PORT" 2>/dev/null; then
  echo "web already listening on ${PORT}"
  exit 0
fi

SITE=$(python3 - <<'PY'
import pathlib
import sys

CABINET = "II-kabinet-buhgaltera-trial-v1.4.1.html"
LANDING = "index.html"

def candidates():
    cwd = pathlib.Path.cwd()
    bases = []
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

for directory in candidates():
    if (directory / CABINET).is_file() and (directory / LANDING).is_file():
        print(directory)
        sys.exit(0)
sys.exit("Could not find the II landing page and cabinet HTML")
PY
)

cd "$SITE"
echo "serving ${SITE} on 0.0.0.0:${PORT}"
exec python3 -m http.server "$PORT" --bind 0.0.0.0
