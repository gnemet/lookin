# Antigravity Rules for Lookin

## 1. Core Behavior
- **Proactive Execution**: Do not ask for permission to verify HTML or test changes.
- **Integrity**: Never modify "copied" files (check source/origin before editing).
- **Static Only**: Lookin MUST remain pure static HTML/CSS/JS — no build step, no server dependency, no npm/webpack/bundlers at runtime.

## 2. Architecture Constraints
- **No Build Step**: Files must work when opened directly in a browser or served by any static file server.
- **npm is optional**: `package.json` exists only for mermaid-cli PNG generation (`generate_png.sh`) — not required at runtime.
- **Single Entry Point**: `index.html` is the only HTML file. All content rendered dynamically.
- **YAML-Driven Config**: Navigation, layers, and TOC defined in `configs/jirada.yaml` (parsed client-side by js-yaml).

## 3. Diagram & Content Standards
- **Mermaid.js**: All architecture diagrams use Mermaid.js with hand-drawn style (`'look': 'handDrawn'`).
- **PNG-First Strategy**: Pre-rendered PNGs preferred over live Mermaid rendering (faster, hand-drawn preserved). Mermaid is fallback.
- **Drill-Down**: Clickable overlay regions on PNG images (positioned by %). Supports 4 action types: drilldown, doc, url, catalog.
- **Markdown Docs**: Rendered via marked.js from `docs/` folder.
- **Catalogs**: JSON table schemas from `catalogs/` folder.

## 4. Self-Documenting
- As an architecture viewer, Lookin IS the documentation. Keep diagrams and YAML config accurate and up-to-date.
