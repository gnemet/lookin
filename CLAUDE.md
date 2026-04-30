# Lookin — Architecture Viewer

Pure static HTML/CSS/JS — single `index.html` entry point.
YAML-driven config, Mermaid.js diagrams (hand-drawn, PNG-first), Phosphor icons, dark theme only.

**This repo has NO build step, NO server dependency, NO npm at runtime.**

## Read before any task

@.agent/rules/antigravity.md
@.agent/rules/ui-ux.md

## Key rules

- **Static only** — files must work when opened directly in a browser or served by any static file server
- **No build step — ever** — `package.json` exists only for Mermaid CLI PNG generation (`generate_png.sh`), not runtime
- **Single entry point**: `index.html` — all content rendered dynamically via `app.js`
- **YAML-driven config**: navigation, layers, TOC from `configs/jirada.yaml` (parsed client-side)
- **Phosphor icons** only — never Font Awesome or any other icon library
- **Dark theme only** — Catppuccin-inspired; light theme is planned, not implemented
- **Vanilla JS only** — no jQuery, no HTMX, no frameworks; vendor: Mermaid.js, js-yaml, marked.js
- **No inline styles / scripts** — all CSS in `style.css`, all logic in `app.js`
- **PNG-first diagrams** — pre-rendered PNGs preferred; Mermaid.js is fallback only

## Diagram generation (PNG)

```bash
./generate_png.sh   # requires npm install (one-time, not runtime)
```

## Deploy

```bash
./deploy_butalam.sh
```
