# pages-publish-pf — Brief

**Problem.** `gnemet.github.io/lookin` is published by a GitHub Actions workflow
(`.github/workflows/pages.yml`). Actions are disabled on the repo, so no push since 2026-09-23 has
reached the site, which still shows the retired JiraDa name and dead links.

**Goal (owner, 2026-10-05: "turn off the action, use own action (pipeline-forge)").**
- **G1** The public landing page is published by a pipeline-forge pipeline, not GitHub Actions.
- **G2** The published set stays exactly what the workflow published: `landing.html` as
  `index.html`, `favicon.svg`, `vendor/`. Nothing else from the repo goes public.
- **G3** One publish path: the Actions workflow file is removed.

**Scope.** lookin only. The prod-server deploy (`OPS-deploy_lookin.md`) is unchanged.
