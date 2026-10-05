# pages-publish-pf — Audit

- **Public surface unchanged.** The publish set is the same three entries the Actions workflow
  copied; `vendor/` is restricted to tracked files (PP-U1), so a stray local file cannot leak.
- **Credentials.** The push uses the operator's existing HTTPS git credential; the pipeline holds none.
- **Serving.** Pages source switched to branch `gh-pages` `/` (legacy build) on 2026-10-05; GitHub
  built and served it although Actions stay disabled on the repo. First publish: `gh-pages` `e9b8b7d`
  from main `ef1bedb`. The settings `PUT` is refused by the office WatchGuard proxy over HTTP/2
  ("header-block invalid"); `curl --http1.1` goes through.
- **Acceptance:** pending (T4) — owner checks `gnemet.github.io/lookin`.
