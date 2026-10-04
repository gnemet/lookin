# themed-tooltip-rollout (lookin leg) — Requirements (EARS)

> Status: active — built and verified on `feature/themed-tooltip`; owner review and the hover walk are open (A9).
> Status legend: `[x]` verified · `[~]` partial · `[ ]` planned.

## U — Ubiquitous

- **U1** `[x]` (G1, G2) `index.html` and `landing.html` **shall** carry a hover hint as `data-tip`, with the text it had as `title`.
- **U2** `[x]` (G1) `app.js` **shall not** write a native `title`, neither as a property nor through `setAttribute`.
- **U3** `[x]` (G1) The repo **shall** carry `tooltip.js` — the floor's script, unchanged — and `index.html` **shall** load it as a plain file, with no build step.
- **U4** `[x]` (G1) `style.css` **shall** carry the floor's `.fui-tip` rule: fixed position, tokens only, no hex and no raw `rgb()` literal.
- **U5** `[x]` (G1) `title=` **shall** remain allowed only as an accessible name on `iframe`, `abbr` and `svg`.
- **U6** `[x]` (G1) Every list of shipped files **shall** name `tooltip.js`, so a deploy never serves an `index.html` that points at a missing script.
- **U7** `[x]` (G3) `scripts/check/check_tooltips.sh` **shall** exit non-zero when U1–U4 or U6 are broken.
