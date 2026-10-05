# pages-publish-pf — Requirements (EARS)

> Status: active
> Status legend: `[x]` verified · `[~]` partial · `[ ]` planned.

- **PP-U1** `[~]` The `OPS-publish_pages` pipeline **shall** assemble the site as exactly
  `index.html` (byte-equal to `landing.html`), `favicon.svg`, `.nojekyll` and the git-tracked files of
  `vendor/`, and nothing else. (G1, G2)
- **PP-E1** `[~]` **When** run with `push=true`, the pipeline **shall** commit the assembled site to the
  `gh-pages` branch and push it to `origin`. (G1)
- **PP-X1** `[~]` **If** the assembled site equals the current `gh-pages` tree, **then** the pipeline
  **shall** make no commit and report "unchanged". (G1)
- **PP-O1** `[~]` **Where** `push` is not `true`, the pipeline **shall** only assemble the site into
  `out` and touch no branch. (G1)
- **PP-U2** `[~]` The repo **shall** carry no GitHub Actions workflow that publishes Pages. (G3)
