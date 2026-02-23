// LookIn — Interactive Architecture Viewer
// YAML-controlled, Mermaid.js powered, hand-drawn style

(function () {
    'use strict';

    let config = null;
    let currentLayer = null;
    let history = [];
    let lang = 'en';

    // ── DOM refs ────────────────────────────────────────────────
    const $diagram = document.getElementById('diagram');
    const $title = document.getElementById('layer-title');
    const $subtitle = document.getElementById('layer-subtitle');
    const $breadcrumb = document.getElementById('breadcrumb');
    const $sourceBadge = document.getElementById('source-badge');
    const $tablePanel = document.getElementById('table-panel');
    const $tableName = document.getElementById('table-name');
    const $tableContent = document.getElementById('table-content');

    // ── Init ────────────────────────────────────────────────────
    async function init() {
        $diagram.innerHTML = '<div class="loading">Loading LookIn...</div>';

        try {
            const yamlText = await fetch('lookin.yaml').then(r => r.text());
            config = jsyaml.load(yamlText);
            document.getElementById('app-title').textContent = 'LookIn';
            setupEvents();
            await navigateTo('overview');
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Error: ${err.message}</div>`;
            console.error('LookIn init error:', err);
        }
    }

    // ── Events ──────────────────────────────────────────────────
    function setupEvents() {
        document.getElementById('btn-home').addEventListener('click', () => navigateTo('overview'));
        document.getElementById('btn-lang').addEventListener('click', toggleLang);
        document.getElementById('btn-close-panel').addEventListener('click', closePanel);

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                if (!$tablePanel.classList.contains('hidden')) {
                    closePanel();
                } else if (history.length > 1) {
                    goBack();
                }
            }
            if (e.key === 'Backspace' && !e.target.matches('input, textarea')) {
                e.preventDefault();
                goBack();
            }
        });
    }

    // ── Navigation ──────────────────────────────────────────────
    async function navigateTo(layerId, catalog) {
        const layer = config.layers.find(l => l.id === layerId);
        if (!layer) {
            console.warn(`Layer ${layerId} not found`);
            return;
        }

        // Handle catalog viewer (Level 4: table columns)
        if (layer.type === 'catalog_viewer' && catalog) {
            await showTableDetail(catalog);
            return;
        }

        currentLayer = layer;
        history.push(layerId);
        updateBreadcrumb();
        updateTitle();
        updateSourceBadge();
        closePanel();

        await renderDiagram(layer);
    }

    function goBack() {
        if (history.length <= 1) return;
        history.pop();
        const prevId = history[history.length - 1];
        history.pop(); // navigateTo will re-add
        navigateTo(prevId);
    }

    // ── Render Diagram ──────────────────────────────────────────
    async function renderDiagram(layer) {
        $diagram.innerHTML = '<div class="loading">Rendering...</div>';

        try {
            let mmdText;
            if (layer.file) {
                mmdText = await fetch(layer.file).then(r => r.text());
            } else {
                mmdText = generateAutoMermaid(layer);
            }

            // Inject handDrawn look if not already in the file
            if (!mmdText.includes('init')) {
                mmdText = `%%{init: {'look': 'handDrawn', 'theme': 'dark'}}%%\n` + mmdText;
            }

            const id = 'mmd-' + Date.now();
            const { svg } = await window.mermaidLib.render(id, mmdText);
            $diagram.innerHTML = svg;

            // Attach click handlers to nodes
            attachNodeClicks(layer);
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Render error: ${err.message}</div>`;
            console.error('Render error:', err);
        }
    }

    // ── Click Handlers ──────────────────────────────────────────
    function attachNodeClicks(layer) {
        if (!layer.nodes) return;

        const svgNodes = $diagram.querySelectorAll('.node');
        svgNodes.forEach(node => {
            const label = node.querySelector('.nodeLabel');
            if (!label) return;

            const text = label.textContent.trim();

            // Find matching node config
            for (const [nodeId, nodeConfig] of Object.entries(layer.nodes)) {
                // Match by node ID or label text (flexible matching)
                if (text.includes(nodeId) || nodeId.toLowerCase() === text.toLowerCase()) {
                    node.style.cursor = 'pointer';

                    if (nodeConfig.tooltip) {
                        node.setAttribute('title', nodeConfig.tooltip);
                    }

                    node.addEventListener('click', () => {
                        if (nodeConfig.drilldown === 'table' && nodeConfig.catalog) {
                            showTableDetail(nodeConfig.catalog);
                        } else if (nodeConfig.drilldown) {
                            navigateTo(nodeConfig.drilldown, nodeConfig.catalog);
                        }
                    });
                    break;
                }
            }
        });
    }

    // ── Table Detail Panel ──────────────────────────────────────
    async function showTableDetail(catalogFile) {
        try {
            // Try to load from catalogs/ directory
            const data = await fetch(`catalogs/${catalogFile}`).then(r => r.json());

            $tableName.textContent = data.title || catalogFile.replace('.json', '');

            let html = '<table><thead><tr>';
            html += '<th>Column</th><th>Type</th><th>Description</th>';
            html += '</tr></thead><tbody>';

            const columns = data.columns || data.fields || [];
            columns.forEach(col => {
                const name = col.field || col.name || col.column_name;
                const type = col.type || col.data_type || '';
                const desc = col.label || col.description || col.comment || '';
                html += `<tr>`;
                html += `<td class="col-name">${name}</td>`;
                html += `<td class="col-type">${type}</td>`;
                html += `<td class="col-desc">${desc}</td>`;
                html += `</tr>`;
            });

            html += '</tbody></table>';
            $tableContent.innerHTML = html;

            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        } catch (err) {
            $tableContent.innerHTML = `<p style="color: var(--text-muted)">Catalog not found: ${catalogFile}</p>`;
            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        }
    }

    function closePanel() {
        $tablePanel.classList.remove('visible');
        $tablePanel.classList.add('hidden');
    }

    // ── Auto-generate Mermaid ───────────────────────────────────
    function generateAutoMermaid(layer) {
        // Fallback: generate a simple diagram from node config
        let mmd = `graph LR\n`;
        if (layer.nodes) {
            const nodeIds = Object.keys(layer.nodes);
            nodeIds.forEach((id, i) => {
                mmd += `    ${id}["${id}"]\n`;
                if (i > 0) mmd += `    ${nodeIds[i - 1]} --> ${id}\n`;
            });
        }
        return mmd;
    }

    // ── UI Updates ──────────────────────────────────────────────
    function updateTitle() {
        const title = lang === 'hu' && currentLayer.title_hu
            ? currentLayer.title_hu
            : currentLayer.title;
        $title.textContent = title;
        $subtitle.textContent = currentLayer.nodes
            ? 'Click any node to drill deeper'
            : '';
    }

    function updateBreadcrumb() {
        let html = '';
        const uniqueHistory = [...new Set(history)];
        uniqueHistory.forEach((id, i) => {
            const layer = config.layers.find(l => l.id === id);
            if (!layer) return;
            const label = lang === 'hu' && layer.title_hu ? layer.title_hu : layer.title;

            if (i < uniqueHistory.length - 1) {
                html += `<span class="crumb" onclick="window.lookInNav('${id}')">${label}</span>`;
                html += `<span class="sep">›</span>`;
            } else {
                html += `<span class="current">${label}</span>`;
            }
        });
        $breadcrumb.innerHTML = html;
    }

    function updateSourceBadge() {
        if (currentLayer.source) {
            const src = config.sources[currentLayer.source];
            if (src) {
                $sourceBadge.textContent = `📦 ${src.label}`;
                $sourceBadge.style.background = `${src.color}30`;
                $sourceBadge.style.color = src.color;
            }
        } else {
            $sourceBadge.textContent = '🔭 LookIn';
        }
    }

    function toggleLang() {
        lang = lang === 'en' ? 'hu' : 'en';
        updateTitle();
        updateBreadcrumb();
    }

    // ── Global navigation API ───────────────────────────────────
    window.lookInNav = function (layerId) {
        // Reset history to this point
        const idx = history.indexOf(layerId);
        if (idx >= 0) history = history.slice(0, idx);
        navigateTo(layerId);
    };

    // ── Start ───────────────────────────────────────────────────
    document.addEventListener('DOMContentLoaded', init);
})();
