# Static-Discipline Rules — lookin

These rules load whenever you work on lookin.

## Build-step-free, forever

The site must work by opening `index.html` directly in a browser. This rules out:

- Any bundler / transpiler at runtime (webpack, vite, rollup, esbuild, parcel)
- Any TypeScript / SCSS / Babel compile step in the load path
- `npm install` as a deployment step (development-only `npm install` for `generate_png.sh` is fine)

The only valid `package.json` purpose: offline diagram generation via `mermaid-cli`. Never extend it.

## Allowed runtime dependencies

```html
<script src="vendor/mermaid.min.js"></script>
<script src="vendor/js-yaml.min.js"></script>
<script src="vendor/marked.min.js"></script>
```

That's it. No others without an explicit conversation.

## Icon library

**Phosphor icons only.** Every other project uses Font Awesome — lookin is the exception. Do not "harmonize" lookin to FA.

## File layout

| File | Purpose |
|---|---|
| `index.html` | Single entry, minimal scaffold |
| `app.js` | All JS — config loading, rendering, drill-down |
| `style.css` | All CSS — dark theme only |
| `configs/<project>.yaml` | Per-project diagram + catalog config |
| `catalogs/<project>/*.yaml` | Per-project drill-down catalog |
| `assets/*.png` | Pre-rendered diagrams (preferred) |
| `assets/*.mmd` | Mermaid sources (PNG-fallback) |

## Drill-down convention

- Overlay regions positioned by **percentage**, never pixels
- Action types: `drilldown`, `doc`, `url`, `catalog`
- Catalog actions resolve into `catalogs/<project>/<catalog>.yaml`

## Deploy

`./deploy_butalam.sh` — copies static files to `sys-butalam.alig.hu`. No build step in the deploy path.

## What lookin currently visualizes

Per `projects.md`, only **jiramntr** is in the catalog (`catalogs/jiramntr/` — 14 files). admin-knowledge has a partial HTML page. Other projects (johanna, aichat, datagrid, mcp-forge, pipeline-forge) are *future* targets — do not claim coverage that does not exist on disk.
