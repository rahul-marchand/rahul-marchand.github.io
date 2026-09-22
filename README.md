# rahul-marchand.github.io

Personal site + research blog. Plain HTML, no generator. Served by GitHub Pages from `main` at rahulmarchand.com (`CNAME`).

- `index.html` — landing page
- `style.css` — shared tokens/typography: Charter (self-hosted in `fonts/`, Bitstream licence), black on white, one red
- `favicon.svg`, `img/penguin.svg` — the penguin from an old badge design (`Penguin.ai`)
- `posts/<slug>/index.html` — built posts (committed build output)
- `build/` — pandoc template + build script

## Building a post

Write the post as markdown (lives in the Obsidian vault — the `.md` is the source of
truth, never edit built HTML). Interactive figures are self-contained HTML fragments
(markup + scoped styles + script, no `<html>/<head>/<body>`), referenced from the
markdown with `<!-- fig: name -->`.

**All text lives in the markdown.** Fragments carry an empty `<figcaption>` anchor;
the caption is authored next to the marker and spliced in at build time:

```markdown
<!-- fig: basin -->
::: {.figcap for=basin}
Caption text — markdown, links and $math$ all work.
:::
```

Appendix prose is plain markdown inside a `<details class="wide" id="app-<id>">` block
(tables and definition lists are styled by style.css). Data-derived numbers quoted in
captions are hand-maintained: when a figure's data.json changes, update the numbers in the md.

**Cross-references** are authored as tokens and resolved at build time from document
order, so reordering renumbers everything, prose included:

- `@fig:<name>` -> linked "Figure N" (`<name>` = the fig marker's name; `@fig:foo.a`
  renders "Figure Na" for panel refs)
- `@tbl:<id>` -> linked "Table N" (give the table's wrapper div the id: `::: {#tbl-<id> .tbl}`)
- `@app:<id>` -> linked "Appendix X" (letters follow `<details>` block order; the build
  prepends "Appendix X: " to each summary, so don't write the letter in the md)

```sh
rsync -a homeserver:projects/GoalMisgeneralisation/figures/fragments/ /tmp/frag/
build/build.sh "$HOME/Documents/Obsidian Vault/400 Blog/decision-threshold.md" decision-threshold /tmp/frag/
git add posts && git commit -m "build post" && git push
```

The build is reproducible: `posts/` should always equal `build(md, fragments)`, so never hand-edit
built HTML — fix the markdown, a fragment, `style.css` or the template instead. `--draft` adds
`noindex`; leave it off for a published post.

Conventions the markdown and fragments must follow:

- Charter has no hair-space glyph: use `&thinsp;` (in `et al.`, around `+`/`−`), never `&hairsp;`.
- Colour tokens in `style.css` stay six-digit hex; the maze figure parses them.
- Fragments may keep asking for `Source Serif 4` / `IBM Plex`; `style.css` aliases the serif to
  Charter and the post template loads Plex, so nothing in the research repo needs to change.
