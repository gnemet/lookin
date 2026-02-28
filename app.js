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
    const $breadcrumb = document.getElementById('breadcrumb');
    const $sourceBadge = document.getElementById('source-badge');
    const $tablePanel = document.getElementById('table-panel');
    const $tableName = document.getElementById('table-name');
    const $tableContent = document.getElementById('table-content');

    // ── Init ────────────────────────────────────────────────────
    async function init() {
        $diagram.innerHTML = '<div class="loading">Loading LookIn...</div>';

        try {
            // Multi-enterprise: ?config=jira-monitor (default)
            const configName = new URLSearchParams(location.search).get('config') || 'jira-monitor';
            const cacheBust = `?v=${Date.now()}`;
            const yamlText = await fetch(`configs/${configName}.yaml` + cacheBust).then(r => {
                if (!r.ok) throw new Error(`Config "${configName}" not found (${r.status})`);
                return r.text();
            });
            config = jsyaml.load(yamlText);
            document.title = `LookIn 🔍 — ${config.title || configName}`;
            // Update footer layer count
            const lc = document.getElementById('layer-count');
            if (lc) lc.textContent = `${config.layers.length} layers`;
            const lu = document.getElementById('last-updated');
            if (lu) lu.textContent = new Date().toLocaleString('hu-HU', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' });
            setupEvents();
            await navigateTo('enterprise');
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Error: ${err.message}</div>`;
            console.error('LookIn init error:', err);
        }
    }

    // ── Events ──────────────────────────────────────────────────
    function setupEvents() {
        document.getElementById('btn-home').addEventListener('click', () => navigateTo('enterprise'));
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

        // Pan-zoom on diagram
        setupPanZoom();
    }

    // ── Pan & Zoom ──────────────────────────────────────────────
    let scale = 1, panX = 0, panY = 0, isPanning = false, startX, startY;

    function setupPanZoom() {
        const container = document.getElementById('diagram-container');

        // Wheel zoom
        container.addEventListener('wheel', (e) => {
            e.preventDefault();
            const delta = e.deltaY > 0 ? 0.9 : 1.1;
            scale = Math.min(5, Math.max(0.3, scale * delta));
            applyTransform();
        }, { passive: false });

        // Drag pan
        container.addEventListener('mousedown', (e) => {
            // Only pan on middle-click or if not clicking a node
            if (e.button === 1 || (e.button === 0 && !e.target.closest('.node-drill, .node-doc'))) {
                isPanning = true;
                startX = e.clientX - panX;
                startY = e.clientY - panY;
                container.style.cursor = 'grabbing';
                e.preventDefault();
            }
        });

        document.addEventListener('mousemove', (e) => {
            if (!isPanning) return;
            panX = e.clientX - startX;
            panY = e.clientY - startY;
            applyTransform();
        });

        document.addEventListener('mouseup', () => {
            isPanning = false;
            document.getElementById('diagram-container').style.cursor = '';
        });

        // Double-click to reset
        container.addEventListener('dblclick', (e) => {
            if (!e.target.closest('.node-drill, .node-doc')) {
                resetZoom();
            }
        });
    }

    function applyTransform() {
        $diagram.style.transform = `translate(${panX}px, ${panY}px) scale(${scale})`;
        $diagram.style.transformOrigin = 'center center';
    }

    function resetZoom() {
        scale = 1; panX = 0; panY = 0;
        applyTransform();
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
        resetZoom();

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

        // Branch: explicit image mode
        if (layer.render === 'image' && layer.image) {
            await renderImageLayer(layer);
            return;
        }

        // Auto-PNG: use pre-rendered PNG only when Mermaid is NOT available
        // When mermaid is loaded, prefer live rendering for clickable nodes
        if (layer.file && layer.file.endsWith('.mmd') && typeof window.mermaidLib === 'undefined') {
            const pngPath = layer.file.replace('.mmd', '.png');
            try {
                const probe = await fetch(pngPath, { method: 'HEAD' });
                if (probe.ok) {
                    await renderImageLayer({ ...layer, image: pngPath, render: 'image' });
                    return;
                }
            } catch (e) { /* PNG not found, fall back to Mermaid */ }
        }

        try {
            let mmdText;
            if (layer.file) {
                mmdText = await fetch(layer.file + '?v=' + Date.now()).then(r => {
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

            // Auto-fit SVG viewBox to show all nodes
            autoFitSVG();

            // Attach click handlers to nodes
            attachNodeClicks(layer);

            console.log(`[LookIn] Rendered layer: ${layer.id}`);
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Render error: ${err.message}</div>`;
            console.error('Render error:', err);
        }
    }

    // ── Render Image Layer (PNG mode) ────────────────────────────
    async function renderImageLayer(layer) {
        try {
            const wrapper = document.createElement('div');
            wrapper.className = 'image-layer';

            const img = document.createElement('img');
            img.src = layer.image + '?v=' + Date.now();
            img.alt = (lang === 'hu' && layer.title_hu) ? layer.title_hu : layer.title;
            img.draggable = false;

            // Wait for image to load to get natural dimensions
            await new Promise((resolve, reject) => {
                img.onload = resolve;
                img.onerror = () => reject(new Error(`Failed to load image: ${layer.image}`));
            });

            wrapper.appendChild(img);

            // Create click-region overlays
            if (layer.clickRegions && Array.isArray(layer.clickRegions)) {
                for (const region of layer.clickRegions) {
                    const [x, y, w, h] = region.rect || [0, 0, 10, 10];
                    const div = document.createElement('div');
                    div.className = 'click-region';
                    div.style.left = x + '%';
                    div.style.top = y + '%';
                    div.style.width = w + '%';
                    div.style.height = h + '%';

                    // Tooltip
                    if (region.tooltip || region.label) {
                        div.title = region.tooltip || region.label;
                        const labelEl = document.createElement('span');
                        labelEl.className = 'region-label';
                        labelEl.textContent = region.label || '';
                        div.appendChild(labelEl);
                    }

                    // Visual indicator: drilldown = gold, doc = blue, url = green
                    if (region.url) {
                        div.classList.add('region-url');
                    } else if (region.doc) {
                        div.classList.add('region-doc');
                    } else if (region.drilldown || region.catalog) {
                        div.classList.add('region-drill');
                    }

                    // Click handler
                    div.addEventListener('click', (e) => {
                        e.stopPropagation();
                        console.log(`[LookIn] Image click-region: ${region.label} → ${region.drilldown || region.doc || region.url || 'static'}`);
                        if (region.url) {
                            window.open(region.url, '_blank');
                        } else if (region.doc) {
                            showDocPanel(region.doc);
                        } else if (region.catalog) {
                            showTableDetail(region.catalog);
                        } else if (region.drilldown) {
                            navigateTo(region.drilldown);
                        }
                    });

                    wrapper.appendChild(div);
                }
            }

            $diagram.innerHTML = '';
            $diagram.appendChild(wrapper);

            console.log(`[LookIn] Rendered image layer: ${layer.id} (${layer.clickRegions?.length || 0} click regions)`);
        } catch (err) {
            $diagram.innerHTML = `<div class="loading">Image error: ${err.message}</div>`;
            console.error('Image render error:', err);
        }
    }

    // ── Auto-fit SVG viewBox to show all nodes ────────────────────
    function autoFitSVG() {
        const svgEl = $diagram.querySelector('svg');
        if (!svgEl) return;

        try {
            const bbox = svgEl.getBBox();
            const pad = 60; // extra room for jiggle animation
            svgEl.setAttribute('viewBox',
                `${bbox.x - pad} ${bbox.y - pad} ${bbox.width + pad * 2} ${bbox.height + pad * 2}`);
            svgEl.removeAttribute('width');
            svgEl.removeAttribute('height');
            svgEl.style.width = '100%';
            svgEl.style.height = 'auto';
            svgEl.style.overflow = 'visible';
            console.log(`[LookIn] Auto-fit viewBox: ${bbox.x},${bbox.y} ${bbox.width}x${bbox.height}`);
        } catch (e) {
            console.warn('[LookIn] autoFitSVG failed:', e);
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

                // Only mark as interactive if node has an action
                const hasAction = nodeConfig.drilldown || nodeConfig.doc || nodeConfig.catalog;
                if (hasAction) {
                    nodeGroup.style.cursor = 'pointer';
                    const cssClass = nodeConfig.doc ? 'node-doc' : 'node-drill';
                    nodeGroup.classList.add(cssClass);
                }

                if (nodeConfig.tooltip) {
                    nodeGroup.setAttribute('title', nodeConfig.tooltip);
                }

                // Single-click = drill down, Double-click = show doc
                let clickTimer = null;

                nodeGroup.addEventListener('click', (e) => {
                    e.stopPropagation();
                    if (clickTimer) return; // ignore if waiting for dblclick
                    clickTimer = setTimeout(() => {
                        clickTimer = null;
                        console.log(`[LookIn] Click: ${nodeId} → ${nodeConfig.drilldown || nodeConfig.catalog || 'static'}`);
                        if (nodeConfig.catalog && !nodeConfig.drilldown) {
                            showTableDetail(nodeConfig.catalog);
                        } else if (nodeConfig.drilldown === 'table' && nodeConfig.catalog) {
                            showTableDetail(nodeConfig.catalog);
                        } else if (nodeConfig.drilldown) {
                            navigateTo(nodeConfig.drilldown, nodeConfig.catalog);
                        }
                    }, 250);
                });

                nodeGroup.addEventListener('dblclick', (e) => {
                    e.stopPropagation();
                    if (clickTimer) { clearTimeout(clickTimer); clickTimer = null; }
                    console.log(`[LookIn] DblClick: ${nodeId} → show doc`);

                    if (nodeConfig.doc) {
                        // Explicit doc property
                        showDocPanel(nodeConfig.doc);
                    } else if (nodeConfig.drilldown && nodeConfig.drilldown !== 'table') {
                        // Try docs/{drilldown}.md first, then fall back to .mmd
                        showDocPanel(nodeConfig.drilldown + '.md');
                    } else if (nodeConfig.catalog) {
                        showTableDetail(nodeConfig.catalog);
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

                        // Only mark as interactive if node has an action
                        const hasAction = nodeConfig.drilldown || nodeConfig.doc || nodeConfig.catalog;
                        if (hasAction) {
                            n.style.cursor = 'pointer';
                            const cssClass = nodeConfig.doc ? 'node-doc' : 'node-drill';
                            n.classList.add(cssClass);
                        }

                        n.addEventListener('click', (e) => {
                            e.stopPropagation();
                            console.log(`[LookIn] Clicked (fallback): ${nodeId}`);
                            if (nodeConfig.doc) {
                                showDocPanel(nodeConfig.doc);
                            } else if (nodeConfig.drilldown === 'table' && nodeConfig.catalog) {
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
    }

    // ── Table Detail Panel ──────────────────────────────────────
    async function showTableDetail(catalogFile) {
        try {
            const data = await fetch(`catalogs/${catalogFile}`).then(r => {
                if (!r.ok) throw new Error(`${r.status}`);
                return r.json();
            });

            $tableName.textContent = data.title || catalogFile.replace('.json', '');

            let html = '';

            // Show table metadata header
            if (data.description || data.schema || data.table_type) {
                html += `<div style="margin-bottom:12px; padding:10px; background:var(--primary-bg); border-radius:8px; font-size:0.82rem;">`;
                if (data.description) html += `<p style="color:var(--text-color); margin:0 0 6px;">${escapeHtml(data.description)}</p>`;
                if (data.schema) html += `<span style="color:var(--info-color); margin-right:12px;">📦 ${escapeHtml(data.schema)}</span>`;
                if (data.table_type) html += `<span style="color:var(--warning-color);">📋 ${escapeHtml(data.table_type)}</span>`;
                html += `</div>`;
            }

            html += '<table><thead><tr>';

            // Detect format: enriched (has type/desc) vs old datagrid format
            const columnsObj = data.columns || (data.datagrid && data.datagrid.columns) || {};

            if (typeof columnsObj === 'object' && !Array.isArray(columnsObj)) {
                const firstVal = Object.values(columnsObj)[0] || {};

                if (firstVal.type || firstVal.desc) {
                    // Enriched format: { col_name: { type, desc } }
                    html += '<th>Column</th><th>Type</th><th>Description</th>';
                    html += '</tr></thead><tbody>';
                    for (const [colName, colConfig] of Object.entries(columnsObj)) {
                        html += `<tr>`;
                        html += `<td class="col-name">${escapeHtml(colName)}</td>`;
                        html += `<td class="col-type">${escapeHtml(colConfig.type || '')}</td>`;
                        html += `<td class="col-desc">${escapeHtml(colConfig.desc || '')}</td>`;
                        html += `</tr>`;
                    }
                } else {
                    // Old datagrid format: { col_name: { labels: {en, hu} } }
                    html += '<th>Column</th><th>Label (EN)</th><th>Label (HU)</th>';
                    html += '</tr></thead><tbody>';
                    for (const [colName, colConfig] of Object.entries(columnsObj)) {
                        const labelEn = colConfig.labels?.en || colName;
                        const labelHu = colConfig.labels?.hu || '';
                        html += `<tr>`;
                        html += `<td class="col-name">${escapeHtml(colName)}</td>`;
                        html += `<td class="col-desc">${escapeHtml(labelEn)}</td>`;
                        html += `<td class="col-desc">${escapeHtml(labelHu)}</td>`;
                        html += `</tr>`;
                    }
                }
            }

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

    // ── Markdown Doc Panel ──────────────────────────────────────
    async function showDocPanel(docFile) {
        try {
            const mdText = await fetch(`docs/${docFile}?v=${Date.now()}`).then(r => {
                if (!r.ok) throw new Error(`${r.status}`);
                return r.text();
            });

            // Strip project prefix and extension: "jiramntr/architecture.md" → "architecture"
            const docName = docFile.split('/').pop().replace('.md', '').replace(/_/g, ' ');
            $tableName.textContent = docName;

            if (window.marked) {
                $tableContent.innerHTML = `<div class="md-content">${window.marked.parse(mdText)}</div>`;
            } else {
                $tableContent.innerHTML = `<pre class="md-content">${escapeHtml(mdText)}</pre>`;
            }

            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        } catch (err) {
            $tableContent.innerHTML = `<p style="color: var(--text-muted)">Doc not found: docs/${docFile}<br><small>${err.message}</small></p>`;
            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        }
    }

    // ── Show .mmd source as doc (dblclick on drill nodes) ───────
    async function showMmdAsDoc(mmdFile, title) {
        try {
            const mmdText = await fetch(mmdFile + '?v=' + Date.now()).then(r => {
                if (!r.ok) throw new Error(`${r.status}`);
                return r.text();
            });

            $tableName.textContent = `📋 ${title}`;
            $tableContent.innerHTML = `
                <div style="margin-bottom:10px; color:var(--text-muted); font-size:0.8rem;">
                    Source: <code>${escapeHtml(mmdFile)}</code>
                </div>
                <pre class="md-content" style="white-space:pre; font-family:'Caveat',cursive; font-size:15px; line-height:1.6; color:var(--text-color);">${escapeHtml(mmdText)}</pre>`;

            $tablePanel.classList.remove('hidden');
            $tablePanel.classList.add('visible');
        } catch (err) {
            $tableContent.innerHTML = `<p style="color: var(--text-muted)">File not found: ${mmdFile}<br><small>${err.message}</small></p>`;
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
        if ($breadcrumb) $breadcrumb.innerHTML = html;
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
