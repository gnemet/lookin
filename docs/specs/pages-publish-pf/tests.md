# pages-publish-pf — Tests

Tier **T1** (local files and a local bare git remote; no network). `scripts/tests/pages_publish_test.sh`.
Committed red, before the pipeline.

| Id | Test | Before the mechanism | Proves |
|---|---|---|---|
| PT1 | `push=false` into a temp `out`: exactly N files, where N = 3 + tracked `vendor/` files; `index.html` byte-equal to `landing.html`; `.nojekyll` present | FAIL — no pipeline | PP-U1, PP-O1 |
| PT2 | `push=true` against a throwaway clone with a local bare `origin`: `origin/gh-pages` exists and its tree lists exactly the PT1 file set | FAIL — no pipeline | PP-E1 |
| PT3 | a second `push=true` run adds no commit to `origin/gh-pages` and prints `unchanged` | FAIL — no pipeline | PP-X1 |
| PT4 | `.github/workflows/` contains no Pages workflow | FAIL — `pages.yml` present | PP-U2 |

Green tests are verification only. Acceptance: the owner sees the new page at `gnemet.github.io/lookin`.
