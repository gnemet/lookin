---
trigger: always_on
---

# UI/UX Rules for Lookin

*Overrides the shared ui-ux rules — Lookin is static HTML, no Go backend.*

## Design Philosophy
- **Modern & Elegant**: Clean, minimal architecture viewer.
- **Card-Based Layout**: Generous whitespace and subtle shadows for diagram containers.
- **Flat UI**: Low contrast, no glossy effects.
- **Dark Theme Only**: Currently dark mode only (Catppuccin-inspired colors). Light theme planned but not implemented.

## Typography
- **Caveat**: Hand-drawn display font for headings.
- **Inter**: System UI font for body text.

## Icons
- **Phosphor Icons**: Icon font (`vendor/phosphor-icons.css`) — NOT Font Awesome.

## Layout
- **Fixed Header** (50px): Logo, breadcrumb trail, control buttons (Home, Back, Lang, TOC).
- **TOC Sidebar** (left): Collapsible groups with curated categories from YAML config.
- **Diagram Container** (center): Pan/zoom with mouse (wheel zoom, drag pan, double-click reset).
- **Table/Doc Panel** (right): Slides in for catalog data or markdown documentation.
- **Fixed Footer** (36px): Status metadata.
- **Responsive**: One breakpoint at 768px for mobile.

## Interactions
- **Vanilla JS Only**: No jQuery, no HTMX, no frameworks.
- **Vendor Libraries**: Mermaid.js (diagrams), js-yaml (config parser), marked.js (markdown renderer).
- **Keyboard Shortcuts**: Escape (back/close/toggle TOC), Backspace (back), T (toggle TOC).
- **Bilingual**: EN/HU toggle via header button.

## Clean Code
- **No Inline Styles**: All styling in `style.css`.
- **No Inline Scripts**: All logic in `app.js`.
- **CSS Variables**: All colors via `:root` variables.
- **No Build Dependencies**: Everything must work as plain static files at runtime.
