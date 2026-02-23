# LookIn 🔭

A YAML-controlled, interactive architecture viewer with hand-drawn Mermaid diagrams. Drill down from business flows to table columns — across multiple projects.

## ✨ Features

- **Hand-drawn style** — sketchy/whiteboard aesthetic
- **YAML-controlled** — define layers, drill-downs, and sources in `lookin.yaml`
- **Multi-project** — wire Jiramntr, Johanna, Datagrid (or any project) into one view
- **Drill-down** — click nodes to zoom: Business → Architecture → Schema → Columns
- **Bilingual** — EN/HU labels
- **100% static** — no backend, open `index.html` in any browser
- **Auto-generated** — layers built from existing MMD files and JSON catalogs

## 🚀 Quick Start

```bash
# Just open in browser
open index.html

# Or serve locally
python3 -m http.server 8000
```

## 📁 Structure

```
lookin/
├── index.html        # Single-page viewer
├── lookin.yaml       # Layer config + drill-down mapping
├── style.css         # Hand-drawn theme
├── app.js            # Navigation + Mermaid rendering
├── layers/           # Mermaid diagrams per layer
│   ├── overview.mmd
│   ├── jiramntr.mmd
│   ├── johanna.mmd
│   └── tables/       # Auto-generated table views
└── README.md
```

## 🔗 Connected Projects

| Project | What | Color |
|---|---|---|
| **Jiramntr** | DWH, ETL, BI, KPI | 🔵 |
| **Johanna** | AI Chat, RAG, LLM | 🟢 |
| **Datagrid** | UI Component Library | 🟠 |
