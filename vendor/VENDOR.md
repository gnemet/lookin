# lookin — vendored assets

lookin is the one repo in the fleet that **cannot** consume the shared foundation-ui asset
bank: it is static HTML with **no build step, ever** (`lookin/CLAUDE.md`,
`languages_and_standards.md:15-16`, root `CLAUDE.md:47`), so there is no Go embed to mount
and no server to mount it on. Files must work when opened directly from disk.

It participates instead through `setup_vendor.sh` — a committed script a human runs to
refresh these files. Owner ruling 2026-09-12: **a human-run sync script is vendoring, not a
build step**; the rule protects *serving*, and nothing has to run for a page to render.

Until 2026-09-12 this repo was the only one with vendored assets and no provenance record.

## Contents

| Asset | Form | Notes |
|---|---|---|
| `phosphor-icons.css` + `fonts/Phosphor.woff2` | `@phosphor-icons/web@2` | floating tag, not a pin — see below |
| `inter.css` · `caveat.css` · `jetbrains-mono.css` | Google Fonts **variable** subsets | latin + latin-ext (Hungarian ő/ű) |
| `fonts/*-Variable-latin{,-ext}.woff2` | the faces those three sheets load | |
| `js-yaml.min.js` 4.1.0 · `marked.min.js` 9.1.6 · `mermaid.min.js` | UMD builds | loaded by `index.html` / `jirada-dev-method.html` |

## Two defects fixed 2026-09-12

**`inter.css` and `caveat.css` pointed at files that do not exist.** They declared static
per-weight faces (`fonts/Inter-Regular.woff2`, `Caveat-SemiBold.woff2`, …) while only the
*variable* subsets were ever vendored. Every `@font-face` silently failed and both families
fell back to the system stack — invisible, because a missing font renders as a different
font rather than as an error. Both rewritten to the variable-plus-`unicode-range` shape that
`jetbrains-mono.css` already had correct.

**`landing.html` loaded its fonts from `fonts.googleapis.com`** while the same three families
sat vendored beside it. That was the only **hard** (non-fallback) CDN reference lookin had —
the project-graph census flagged it, and it is now closed by pointing at the local sheets.

## Still open — owner decisions, not oversights

- **`configs/chalkboard.css:1` still `@import`s Google Fonts.** It needs *Patrick Hand*,
  which is **not** vendored here, so it cannot be closed the way `landing.html` was without
  admitting a new font. `lookin-cdn-vendoring` decision (c) describes this file as used by
  the offline `generate_png.sh` only — the graph census shows `landing.html` referenced the
  same URL too, so that description was incomplete; after this change it is accurate again.
- **The six `onerror` CDN fallbacks** in `index.html` / `jirada-dev-method.html`. These are
  the *sanctioned* vendor-first form (`presentation_decks.md:26-31`, `:121`) **if** those
  pages count as decks — an open question. `lookin-cdn-vendoring` decision (a) is exactly
  "keep or drop" them, and the census now answers it with data: four fallback-only edges.
- **Phosphor is pinned to a floating `@2` tag**, so a refresh can change bytes without any
  record changing. The fleet's other ten copies are `2.1.1`
  (`md5 7fe7108986e8596a197c607b2d989d89`); this one differs slightly. Pinning it to 2.1.1
  would align lookin with everyone else.

## Refreshing

Run `setup_vendor.sh`. It records every upstream URL and version, and it is the only
sanctioned way these files change — hand-editing a vendored build leaves no trace that it
diverged from upstream.

⚠ `setup_vendor.sh` still downloads the **old static** font filenames
(`Inter-Regular.woff2` etc.). Re-running it today adds a second, differently-named set
rather than refreshing the variable ones the CSS now uses. Fix the script before the next
refresh, or it will quietly re-create the state this record was written to close.
