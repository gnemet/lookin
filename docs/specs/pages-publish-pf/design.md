# pages-publish-pf — Design

**Mechanism.** `pipelines/OPS-publish_pages.md`, run from the lookin repo root
(`bin/pf pipelines/OPS-publish_pages.md --arg push=true`). Two `shell` steps:

1. `assemble` copies the site manifest into `out` (default: a fresh temp dir). The manifest is the
   `SITE` list in the step: one line per entry, `source → published path`. `vendor/` is copied from
   `git ls-files`, so untracked files never go public.
2. `publish` (only when `push=true`) checks `gh-pages` out in a temporary `git worktree` (an orphan
   branch on first run), replaces its whole tree with `out`, commits if the tree changed, pushes
   `origin gh-pages`, then removes the worktree. The working branch of the checkout is never touched.

**Serving.** GitHub Pages switches from `build_type: workflow` to the branch source
`gh-pages` `/` (one-time repo setting, owner's account, done via the REST API after the first push).
`.nojekyll` stops a Jekyll pass over the files.

**Removed.** `.github/workflows/pages.yml` (G3).

**Not changed.** Butalam deploy pipeline; the site's content.
