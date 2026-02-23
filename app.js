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
        document.getElementById('btn-back').addEventListener('click', goBack);
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
            console.warn(`Layer "${layerId}" not found`);
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
                mmdText = await fetch(layer.file).then(r => {
                    if (!r.ok) throw new Error(`Failed to load ${layer.file}: ${r.status}`);
                    return r.text();
                });
            } else {
                mmdText = generateAutoMermaid(layer);
            }

            // Inject handDrawn look if not already present
            if (!mmdText.includes('init')) {
                mmdText = `%%{init: {'look': 'handDrawn', 'theme': 'dark'}}%%\n` + mmdText;
            } else if (!mmdText.includes('handDrawn')) {
                mmdText = mmdText.replace("{'theme'", "{'look': 'handDrawn', 'theme'");
            }

            const id = 'mmd-' + Date.now();
            const { svg } = await window.mermaidLib.render(id, mmdText);
            $diagram.innerHTML = svg;

            // Attach click handlers to nodes
            attachNodeClicks(layer);

            console.log(`[LookIn] Rendered layer: ${layer.id}`);
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Render error: ${err.message}</div>`;
            console.error('Render error:', err);
        }
    }

    // ── Click Handlers (fixed: match by SVG node ID) ────────────
    function attachNodeClicks(layer) {
        if (!layer.nodes) return;

        // Mermaid generates SVG nodes with IDs like:
        // "flowchart-NODEID-0", "flowchart-NODEID-1", etc.
        // We match the YAML nodeId against the SVG element ID attribute.
        const svgEl = $diagram.querySelector('svg');
        if (!svgEl) return;

        let matchCount = 0;

        for (const [nodeId, nodeConfig] of Object.entries(layer.nodes)) {
            // Strategy 1: Find by SVG element ID containing the node name
            // Mermaid uses IDs like "flowchart-DWH-0" or "flowchart-JOHANNA-12"
            const nodeEl = svgEl.querySelector(`[id*="flowchart-${nodeId}-"]`) ||
                svgEl.querySelector(`[id*="${nodeId}"]`);

            if (nodeEl) {
                // Find the closest .node group element
                const nodeGroup = nodeEl.closest('.node') || nodeEl;

                nodeGroup.style.cursor = 'pointer';
                nodeGroup.classList.add('clickable');

                if (nodeConfig.tooltip) {
                    nodeGroup.setAttribute('title', nodeConfig.tooltip);
                }

                nodeGroup.addEventListener('click', (e) => {
                    e.stopPropagation();
                    console.log(`[LookIn] Clicked: ${nodeId} → ${nodeConfig.drilldown || 'table'}`);

                    if (nodeConfig.drilldown === 'table' && nodeConfig.catalog) {
                        showTableDetail(nodeConfig.catalog);
                    } else if (nodeConfig.drilldown) {
                        navigateTo(nodeConfig.drilldown, nodeConfig.catalog);
                    }
                });

                matchCount++;
                console.log(`[LookIn] Bound click: ${nodeId} (${nodeConfig.drilldown || 'table'})`);
            } else {
                // Strategy 2: Fallback — search all .node elements by label text
                const allNodes = svgEl.querySelectorAll('.node');
                for (const n of allNodes) {
                    const label = n.querySelector('.nodeLabel');
                    if (!label) continue;
                    const text = label.textContent.trim();

                    // Flexible match: check if label contains the nodeId
                    if (text.toUpperCase().includes(nodeId.toUpperCase()) ||
                        nodeId.toUpperCase().includes(text.toUpperCase().replace(/[^A-Z]/g, '').substring(0, 4))) {

                        n.style.cursor = 'pointer';
                        n.classList.add('clickable');

                        n.addEventListener('click', (e) => {
                            e.stopPropagation();
                            console.log(`[LookIn] Clicked (fallback): ${nodeId}`);
                            if (nodeConfig.drilldown === 'table' && nodeConfig.catalog) {
                                showTableDetail(nodeConfig.catalog);
                            } else if (nodeConfig.drilldown) {
                                navigateTo(nodeConfig.drilldown, nodeConfig.catalog);
                            }
                        });

                        matchCount++;
                        console.log(`[LookIn] Bound click (fallback): ${nodeId} via text "${text}"`);
                        break;
                    }
                }
            }
        }

        console.log(`[LookIn] Matched ${matchCount}/${Object.keys(layer.nodes).length} clickable nodes`);

        // Add jiggle animation to clickable nodes (JS for SVG compatibility)
        startJiggle();
    }

    // ── SVG Jiggle Animation (CSS transforms don't work on SVG <g>) ──
    let jiggleTimers = [];

    function startJiggle() {
        // Clear any existing timers
        jiggleTimers.forEach(t => clearInterval(t));
        jiggleTimers = [];

        const clickables = $diagram.querySelectorAll('.clickable');
        clickables.forEach((node, i) => {
            // Each node gets a different random interval
            const delay = 2000 + (i * 700) + Math.random() * 1500;

            const timer = setInterval(() => {
                // Only jiggle if not hovered
                if (node.matches(':hover')) return;

                // Get current transform (preserve existing Mermaid translate)
                const existing = node.getAttribute('transform') || '';
                const baseTransform = existing.replace(/translate\([^)]*\)\s*rotate\([^)]*\)/g, '').trim()
                    || existing;

                // Quick 3-step wobble
                const steps = [
                    { offset: 0, r: 0, tx: 0, ty: 0 },
                    { offset: 50, r: 0.6, tx: 0.8, ty: -0.5 },
                    { offset: 100, r: -0.4, tx: -0.5, ty: 0.3 },
                    { offset: 150, r: 0.2, tx: 0.3, ty: 0.2 },
                    { offset: 200, r: 0, tx: 0, ty: 0 }
                ];

                steps.forEach(step => {
                    setTimeout(() => {
                        if (step.r === 0) {
                            node.setAttribute('transform', baseTransform);
                        } else {
                            // Get node center for rotation
                            const bbox = node.getBBox ? node.getBBox() : { x: 0, y: 0, width: 0, height: 0 };
                            const cx = bbox.x + bbox.width / 2;
                            const cy = bbox.y + bbox.height / 2;
                            node.setAttribute('transform',
                                `${baseTransform} translate(${step.tx}, ${step.ty}) rotate(${step.r}, ${cx}, ${cy})`);
                        }
                    }, step.offset);
                });
            }, delay);

            jiggleTimers.push(timer);
        });
    }

    // ── Table Detail Panel ──────────────────────────────────────
    async function showTableDetail(catalogFile) {
        try {
            const data = await fetch(`catalogs/${catalogFile}`).then(r => {
                if (!r.ok) throw new Error(`${r.status}`);
                return r.json();
            });

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
                html += `<td class="col-name">${escapeHtml(name)}</td>`;
                html += `<td class="col-type">${escapeHtml(type)}</td>`;
                html += `<td class="col-desc">${escapeHtml(desc)}</td>`;
                html += `</tr>`;
            });

            html += '</tbody></table>';
            $tableContent.innerHTML = html;

            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        } catch (err) {
            $tableContent.innerHTML = `<p style="color: var(--text-muted)">Catalog not found: ${catalogFile}<br><small>${err.message}</small></p>`;
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
            ? '👆 Click any node to drill deeper'
            : '← Press Escape to go back';
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
        document.getElementById('btn-lang').textContent = lang === 'en' ? '🌐' : '🇭🇺';
        updateTitle();
        updateBreadcrumb();
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // ── Global navigation API ───────────────────────────────────
    window.lookInNav = function (layerId) {
        const idx = history.indexOf(layerId);
        if (idx >= 0) history = history.slice(0, idx);
        navigateTo(layerId);
    };

    // ── Start ───────────────────────────────────────────────────
    document.addEventListener('DOMContentLoaded', init);
})();
