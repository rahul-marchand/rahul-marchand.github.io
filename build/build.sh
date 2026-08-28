#!/usr/bin/env bash
# Build a post: markdown -> posts/<slug>/index.html
# Usage: build/build.sh <post.md> <slug> [figures-dir]
# Figure markers in the markdown:  <!-- fig: name -->  ->  spliced from <figures-dir>/name.html
set -euo pipefail

md="$1"; slug="$2"; figdir="${3:-}"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/posts/$slug"
mkdir -p "$out"

pandoc "$md" --template "$root/build/template.html" --mathjax -o "$out/index.html"

if [[ -n "$figdir" ]]; then
  python3 - "$out/index.html" "$figdir" <<'EOF'
import re, sys, pathlib
page, figdir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
html = page.read_text()
def splice(m):
    f = figdir / (m.group(1) + ".html")
    return f.read_text() if f.exists() else m.group(0)
page.write_text(re.sub(r"<!--\s*fig:\s*([\w-]+)\s*-->", splice, html))
EOF
fi
echo "built: $out/index.html"
