# Brief — themed-tooltip-rollout (lookin leg)

## Intent

lookin's leg of the platform item `themed-tooltip-rollout`
(`../../../../docs/urgent_tasks.md`, owning repo `foundation-ui`). Owner ruling 2026-09-26
(`../../../../docs/rules/02_coding_implementation/ui_and_styling.md` § Tooltips): the native `title=` bubble is OS chrome. It ignores the theme, cannot be styled and is
not keyboard-visible, so every hover / focus hint rides `data-tip` and one themed tooltip shows it.

## Goals

- **G1** No lookin surface shows a native tooltip.
- **G2** The hint text itself does not change — only the attribute that carries it.
- **G3** A regression is caught by a test, not by review.

## Where lookin stands

lookin is static HTML with no build step and no server; it is a structural opt-out of the
foundation-ui asset bank (`foundation-ui/CLAUDE.md`, vendor-bank register). The viewer
(`index.html` + `app.js`) carried four `title=` attributes on its header buttons and wrote two
native titles at runtime (a click region's hint, a diagram node's hint).

`jirada-dev-method.html` carries eight more, but it is a **generated** deck (`DOC-deck_build`
from `docs/presentation/jirada-dev-method.deck.md`, "do not edit"): its chrome comes from the
foundation-ui deck engine. `landing.html` has none.

## Scope

- Convert the four `index.html` attributes to `data-tip`; the one icon-only button keeps its name as `aria-label`.
- Convert the two runtime sites in `app.js` to `setAttribute('data-tip', …)`.
- Carry a byte-identical copy of the floor's `tooltip.js` at the repo root and the floor's `.fui-tip`
  rule in `style.css`; load the script from `index.html`.
- Add `tooltip.js` to the two lists of shipped files (`deploy.sh`, `pipelines/OPS-deploy_lookin.md`).
- Add `scripts/check/check_tooltips.sh` as the T1 scan.

## Out of scope (A10)

- `jirada-dev-method.html` — generated; its hints change in the foundation-ui deck engine, then by a rebuild.
- `vendor/` (third-party, gitignored) and `node_modules/`.
- Any other finding; a second defect is reported in `audit.md`, not fixed.
