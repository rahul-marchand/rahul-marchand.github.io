#!/usr/bin/env bash
# Build a post: markdown -> posts/<slug>/index.html
# Usage: build/build.sh <post.md> <slug> [figures-dir] [--draft]
# Figure markers in the markdown:  <!-- fig: name -->  ->  spliced from <figures-dir>/name.html
# Cross-references: @fig:<name>, @tbl:<id>, @app:<id> (optional .suffix, e.g. @fig:task-planning.a)
# become linked "Figure N" / "Table N" / "Appendix X", numbered from document order.
# Anchors: figures get id="fig-<name>" at splice time; tables need a pandoc div id
# (::: {#tbl-<id> ...}); appendix <details> need id="app-<id>".
# --draft adds <meta name="robots" content="noindex">
set -euo pipefail

md="$1"; slug="$2"; figdir="${3:-}"
[[ "$figdir" == "--draft" ]] && figdir=""
draft=(); [[ "${*: -1}" == "--draft" ]] && draft=(-M draft=true)
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/posts/$slug"
mkdir -p "$out"

pandoc "$md" -f markdown-citations --template "$root/build/template.html" \
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
    name = m.group(1)
    f = figdir / (name + ".html")
    if not f.exists():
        return m.group(0)
    frag = f.read_text()
    # our anchor replaces any id the fragment shipped with
    frag = re.sub(r'(<figure )(id="[^"]*" )?', rf'\1id="fig-{name}" ', frag, count=1)
    cap = caps.get(name)
    if cap:
        frag = re.sub(
            r"(<figcaption[^>]*>).*?(</figcaption>)",
            lambda mm: mm.group(1) + cap + mm.group(2),
            frag, count=1, flags=re.S,
        )
    return frag

html = re.sub(r"<!--\s*fig:\s*([\w-]+)\s*-->", splice, html)

# Cross-references. Numbering mirrors the CSS counters: every <figure> increments
# the figure counter, every <table> the table counter, every <details> is a letter.
refs = {}
for n, m in enumerate(re.finditer(r'<figure id="fig-([\w-]+)"', html), 1):
    refs[("fig", m.group(1))] = f"Figure {n}"
n_tbl = 0
pending = None
for m in re.finditer(r'<div id="tbl-([\w-]+)"[^>]*>|<table[\s>]', html):
    if m.group(1):
        pending = m.group(1)
    else:
        n_tbl += 1
        if pending:
            refs[("tbl", pending)] = f"Table {n_tbl}"
            pending = None
letters = []
def letter_summary(m):
    letters.append(m.group(1))
    x = chr(ord("A") + len(letters) - 1)
    return f'{m.group(0).split("<summary>")[0]}<summary>Appendix {x}: '
html = re.sub(r'<details[^>]*id="app-([\w-]+)"[^>]*>\s*<summary>', letter_summary, html)
for i, name in enumerate(letters):
    refs[("app", name)] = f"Appendix {chr(ord('A') + i)}"

def link(m):
    kind, name, suffix = m.group(1), m.group(2), m.group(3) or ""
    text = refs.get((kind, name))
    if text is None:
        raise SystemExit(f"unresolved reference @{kind}:{name}")
    return f'<a class="xref" href="#{kind}-{name}">{text}{suffix}</a>'

html = re.sub(r"@(fig|tbl|app):([\w-]+?)(?:\.(\w+))?(?=[\s.,;:)<'’])", link, html)
page.write_text(html)
EOF
fi
echo "built: $out/index.html"
