# lookin — Architecture viewer

> Platform rules live in `../all_rules_for_claude.md` (root). This file only carries lookin-specific deltas.
> Last refreshed: 2026-05-15.

Pure static HTML/CSS/JS — single `index.html` rendered dynamically by `app.js`. YAML-driven config (`configs/jirada.yaml`). Hand-drawn Mermaid diagrams (PNG-first). Phosphor icons. Dark theme only.

## Project-specific rules
- **NO build step, ever.** Files must work when opened directly in a browser. `package.json` exists only for offline `generate_png.sh` (mermaid-cli) — not runtime.
- Vendor libs only: Mermaid.js, js-yaml, marked.js. Vanilla JS — no jQuery, HTMX, or frameworks.
- Phosphor icons only — never Font Awesome.
- No inline `<style>` / `<script>` — CSS in `style.css`, JS in `app.js`.
- PNG diagrams preferred (pre-rendered); Mermaid.js is fallback.
- Drill-down: clickable overlay regions positioned by `%`. Action types: drilldown, doc, url, catalog.

## Commands
- `./generate_png.sh` — regenerate diagrams (one-time, requires `npm install`).
- `./deploy_butalam.sh` — deploy.
