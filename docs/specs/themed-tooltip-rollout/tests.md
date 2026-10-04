# themed-tooltip-rollout (lookin leg) — Tests

All tests are tier **T1** (static: files only, no network, no database). They were committed red
before the conversion.

| Id | Test | Before the conversion | Proves |
|---|---|---|---|
| TS1 | no native `title=` in `index.html` / `landing.html` | FAIL — 4 findings | U1, U5 |
| TS2 | `app.js` writes no native title | FAIL — 2 findings | U2 |
| TS3 | `tooltip.js` exists, holds the script contract, and `index.html` loads it | FAIL — missing file | U3 |
| TS4 | `style.css` has the `.fui-tip` rule, fixed and token-only | FAIL — no rule | U4 |
| TS5 | both shipped-file lists name `tooltip.js` | FAIL — 2 findings | U6 |

A green suite is verification only. Acceptance is the owner's hover walk on both themes
(`audit.md`).
