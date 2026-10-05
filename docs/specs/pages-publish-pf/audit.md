# pages-publish-pf — Audit

- **Public surface unchanged.** The publish set is the same three entries the Actions workflow
  copied; `vendor/` is restricted to tracked files (PP-U1), so a stray local file cannot leak.
- **Credentials.** The push uses the operator's existing HTTPS git credential; the pipeline holds none.
- **Acceptance:** pending (T4).
