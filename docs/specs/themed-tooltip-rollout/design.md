# themed-tooltip-rollout (lookin leg) — Design

## Mechanism

The floor's `tooltip.js` shows a `data-tip` in one `role="tooltip"` element through delegated
listeners on `document`, so regions and diagram nodes that `app.js` builds at runtime need no
re-binding. `closest('[data-tip]')` works on SVG elements too, so a Mermaid node group shows its
hint the same way — the native `title` attribute it carried before never rendered on an SVG group.

The script is a plain file beside `app.js`, loaded by a `<script src>` tag: the page still works
when opened directly in a browser. It is the platform's own script, not a third-party library, so
it does not live under `vendor/`.

## Changes

| Where | Change |
|---|---|
| `index.html` | 4 × `title=` → `data-tip=`; `aria-label` on the icon-only tree button; one `<script src="tooltip.js">` tag |
| `app.js` | `div.title = …` and `setAttribute('title', …)` → `setAttribute('data-tip', …)` |
| `tooltip.js` | new — byte-identical copy of `foundation-ui/ui/js/tooltip.js` |
| `style.css` | a token bridge, then the floor's `.fui-tip` rule, byte-identical |
| `deploy_butalam.sh`, `pipelines/OPS-deploy_lookin.md` | `tooltip.js` added to the core file list |
| `scripts/check/check_tooltips.sh` | new — the T1 scan (TS1–TS5) |

## Tokens

The floor rule reads `--bg-card`, `--fg`, `--border`, `--r-md`, `--font-sans` and `--base-rgb`.
The bridge maps them onto `--card-bg`, `--text-color`, `--border-color` and `--font-ui`, scoped to
the tooltip element. lookin has no small-radius token and no neutral `-rgb` companion, so the
bridge declares those two values itself (a 4px radius; the shadow colour). lookin is dark-only,
so there is no second palette to follow.
