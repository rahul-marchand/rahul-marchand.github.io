#!/usr/bin/env bash
# Build a post: markdown -> posts/<slug>/index.html
# Usage: build/build.sh <post.md> <slug> [figures-dir] [--draft]
# Figure markers in the markdown:  <!-- fig: name -->  ->  spliced from <figures-dir>/name.html
# --draft adds <meta name="robots" content="noindex">
set -euo pipefail

md="$1"; slug="$2"; figdir="${3:-}"
[[ "$figdir" == "--draft" ]] && figdir=""
draft=(); [[ "${*: -1}" == "--draft" ]] && draft=(-M draft=true)
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/posts/$slug"
mkdir -p "$out"

pandoc "$md" --template "$root/build/template.html" \
  --mathjax=https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml-full.js \
  "${draft[@]}" -o "$out/index.html"

if [[ -n "$figdir" ]]; then
  python3 - "$out/index.html" "$figdir" <<'EOF'
import re, sys, pathlib
page, figdir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
html = page.read_text()

# captions authored in the post markdown override a fragment's built-in one:
#   ::: {.figcap for=<name>} ... :::
caps = {}
def take(m):
    caps[m.group(1)] = m.group(2).strip()
    return ""
html = re.sub(
    r'<div[^>]*class="figcap"[^>]*(?:data-)?for="([\w-]+)"[^>]*>(.*?)</div>\s*',
    take, html, flags=re.S,
)

def splice(m):
    f = figdir / (m.group(1) + ".html")
    if not f.exists():
        return m.group(0)
    frag = f.read_text()
    cap = caps.get(m.group(1))
    if cap:
        frag = re.sub(
            r"(<figcaption[^>]*>).*?(</figcaption>)",
            lambda mm: mm.group(1) + cap + mm.group(2),
            frag, count=1, flags=re.S,
        )
    return frag

page.write_text(re.sub(r"<!--\s*fig:\s*([\w-]+)\s*-->", splice, html))
EOF
fi
echo "built: $out/index.html"
