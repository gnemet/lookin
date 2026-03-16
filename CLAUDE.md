# Lookin — Architecture Viewer

Pure static HTML/CSS/JS — single `index.html` entry point.
YAML-driven config, Mermaid.js diagrams (hand-drawn, PNG-first), Phosphor icons, dark theme only.

## Agent Rules
Always read all files before starting work:
- `.agent/rules/` — repo-specific rules (static-only, Mermaid, Phosphor, dark theme, YAML config)

Note: Lookin does NOT use the shared go-backend/pg/ui-ux rules — it is pure static HTML/CSS/JS with its own UI conventions.
