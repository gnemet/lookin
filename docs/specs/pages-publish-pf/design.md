# pages-publish-pf — Design

**Mechanism.** `pipelines/OPS-publish_pages.md`, run from the lookin repo root
(`bin/pf pipelines/OPS-publish_pages.md --arg push=true`). Two `shell` steps:

1. `assemble` copies the site manifest into `out` (default: a fresh temp dir). The manifest is the
   `SITE` list in the step: one line per entry, `source → published path`. `vendor/` is copied from
   `git ls-files`, so untracked files never go public.
2. `publish` (only when `push=true`) builds the commit with git plumbing: a temporary index over
   `out` → `write-tree` → `commit-tree`, parented on the remote `gh-pages` head when it exists (no
   parent on the first run). An unchanged tree makes no commit. It pushes `<commit>:refs/heads/gh-pages`;
   no worktree, and the checked-out branch is never touched.

**Serving.** GitHub Pages switches from `build_type: workflow` to the branch source
`gh-pages` `/` (one-time repo setting, owner's account, done via the REST API after the first push).
`.nojekyll` stops a Jekyll pass over the files.

**Removed.** `.github/workflows/pages.yml` (G3).

**Not changed.** The prod-server deploy pipeline; the site's content.
