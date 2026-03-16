# LookIn 🔭

A YAML-controlled, interactive architecture viewer with hand-drawn Mermaid diagrams. Drill down from business flows to table columns — across multiple projects.

Deployed at: [gnemet.github.io/lookin](https://gnemet.github.io/lookin/)

## ✨ Features

- **Hand-drawn style** — chalkboard-aesthetic PNG diagrams
- **YAML-controlled** — define layers, drill-downs, and sources in `configs/jirada.yaml`
- **TOC Sidebar** — collapsible category groups with curated navigation
- **Doc Panel** — right-side panel slides in for catalog data or markdown documentation
- **Multi-project** — wire Jiramntr, Johanna, Datagrid (or any project) into one view
- **Drill-down** — click nodes to zoom: Business → Architecture → Schema → Columns
- **PNG Presentation Mode** — pre-rendered PNG diagrams for offline/LAN use (no mermaid.js required)
- **Doc Manifest** — `doc_manifest.yaml` tracks per-diagram documentation metadata
- **Bilingual** — EN/HU toggle via header button
- **100% static** — no backend, open `index.html` in any browser
- **Auto-generated** — `generate_docs.py` builds documentation, `generate_png.sh` renders diagrams
- **GitHub Pages** — auto-deployed to `gnemet.github.io/lookin`

## 🚀 Quick Start

```bash
# Just open in browser
open index.html

# Or serve locally
python3 -m http.server 8000

# Regenerate docs from source projects
python3 generate_docs.py

# Regenerate PNG diagrams (requires Puppeteer)
./generate_png.sh
```

## 📁 Structure

```
lookin/
├── index.html          # Single-page viewer
├── app.js              # Navigation, TOC, pan/zoom, Mermaid rendering
├── style.css           # Catppuccin dark theme
├── configs/
│   └── jirada.yaml     # Layer config + drill-down mapping
├── layers/             # Mermaid diagrams per project
│   ├── overview/       # Platform overview
│   ├── jiramntr/       # DWH architecture layers (10 diagrams)
│   ├── johanna/        # AI chat architecture
│   ├── mcp-forge/      # RAG pipeline
│   └── aichat/         # AI module
├── docs/               # Markdown documentation per layer
│   ├── jiramntr/       # 9 docs (architecture, star_schema, security...)
│   ├── johanna/        # AI pipeline docs
│   └── mcp-forge/      # RAG builder docs
├── catalogs/           # JSON table catalogs for data panel
├── doc_manifest.yaml   # Doc freshness tracking
├── generate_docs.py    # Auto-generate docs from source projects
├── generate_png.sh     # Render MMD → PNG (chalkboard style)
└── deploy_butalam.sh   # Deploy to LAN server
```

## 🔗 Connected Projects

| Project | What | Color |
|---|---|---|
| **Jiramntr** | DWH, ETL, BI, KPI | 🔵 |
| **Johanna** | AI Chat, RAG, LLM | 🟢 |
| **Datagrid** | UI Component Library | 🟠 |
| **MCP-Forge** | RAG Pipeline | 🟣 |
| **AiChat** | AI Module | 🟡 |
