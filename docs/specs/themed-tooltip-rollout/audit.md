# themed-tooltip-rollout (lookin leg) — Audit

## Verification (AI, 2026-10-04)

- `scripts/check/check_tooltips.sh` exits 0. Red before, 11 findings: 4 × TS1, 2 × TS2, 2 × TS3, 1 × TS4, 2 × TS5.
- `diff tooltip.js ../foundation-ui/ui/js/tooltip.js` — identical at copy time.
- `bash -n deploy.sh` clean; `pf --validate pipelines/OPS-deploy_lookin.md` OK (two env-var warnings, expected off the deploy host).
- Nothing was deployed and the page was not opened in a browser.

## Residual risk and open items

- **Not walked in a browser.**
- **Owner call — a fourth runtime script.** `.claude/rules/static-discipline.md` lists three allowed runtime dependencies and says no others without an explicit conversation; `CLAUDE.md` says all JS lives in `app.js`. `tooltip.js` is the platform's own script, carried as a separate file because the rollout requires a byte-identical copy (it cannot be folded into `app.js` and stay comparable). The rollout item names lookin as carrying that copy; the two lookin rule lines are not updated here and want the owner's word.
- **`jirada-dev-method.html` still carries eight native tooltips** on its navigation buttons. It is generated; the fix belongs to the foundation-ui deck engine and a rebuild of the deck. Owner: the `themed-tooltip-rollout` item's foundation-ui leg.
- **Stacking.** The floor rule's `z-index` is 1000; lookin's document panel and modal sit at 1500 and 2000. A hint on a control inside those overlays would render underneath. No converted control is inside one today. The rule is kept byte-identical rather than adjusted.
- **Byte-identity is checked by hand** (`diff` against the floor's file at copy time); the check script pins the script's contract, not its bytes.
- The check is not wired into CI or a hook; it is run by hand.

## Acceptance (A9)

- Diff review: open — owner.
- Hover walk on every theme (pointer, keyboard focus, Escape): open — owner. Not done in this
  session; no browser walk was run.
