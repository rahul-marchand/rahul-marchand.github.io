# rahul-marchand.github.io

Personal site + research blog. Plain HTML, no generator. Served by GitHub Pages from `main`.

- `index.html` — landing page
- `style.css` — shared tokens/typography (same palette as the interactive figures)
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

Appendix prose is plain markdown inside a `<details class="wide">` block (tables and
definition lists are styled by style.css). Data-derived numbers quoted in captions are
hand-maintained: when a figure's data.json changes, update the numbers in the md.

```sh
build/build.sh path/to/post.md decision-threshold path/to/figures/
git add posts && git commit -m "build post" && git push
```

Figure fragments come from the research repo (`homeserver:~/projects/GoalMisgeneralisation/figures/`).
