/* tooltip.js — the platform's one themed tooltip (ui_and_styling.md § Tooltips; spec
 * docs/specs/themed-tooltip/). The native title= bubble is OS chrome that ignores the theme,
 * so a hint rides a data-tip attribute and this script shows it in a single role="tooltip"
 * element styled by .fui-tip (shell.css, tokens only).
 *
 * Why JavaScript and not a CSS ::after: the element is position: fixed, so it is never clipped by
 * a scroll pane (a collapsed sidebar's icon labels), it attaches to void elements (<input>) too,
 * and no host needs position: relative. Listeners are delegated on document, so content swapped
 * in by htmx needs no re-binding. Text only — textContent, never markup. Escape hides it.
 *
 * Keyboard focus shows the hint only where the element's own label is not readable (spec
 * docs/specs/sidebar-tree-nav/ K10); the pointer always shows it.
 */
(function () {
  'use strict';
  var GAP = 6, EDGE = 8, PX = 12, PY = 18, ID = 'fui-tip';
  var tip = null, host = null;

  function el() {
    if (!tip) {
      tip = document.createElement('div');
      tip.id = ID;
      tip.className = 'fui-tip';
      tip.setAttribute('role', 'tooltip');
      tip.hidden = true;
      document.body.appendChild(tip);
    }
    return tip;
  }

  // Beside the element — keyboard focus has no pointer to anchor to (E4).
  function place(h, d) {
    var r = h.getBoundingClientRect();
    var w = d.offsetWidth, ht = d.offsetHeight;
    var x = Math.min(Math.max(EDGE, r.left), window.innerWidth - w - EDGE);
    var y = r.bottom + GAP;
    if (y + ht > window.innerHeight - EDGE) { y = r.top - ht - GAP; }
    d.style.left = Math.round(x) + 'px';
    d.style.top = Math.round(y) + 'px';
  }

  // At the pointer, below-right of the cursor; flipped left/above where the viewport ends (E1).
  function placeAt(cx, cy, d) {
    var w = d.offsetWidth, ht = d.offsetHeight;
    var x = cx + PX, y = cy + PY;
    if (x + w > window.innerWidth - EDGE) { x = cx - w - PX; }
    if (y + ht > window.innerHeight - EDGE) { y = cy - ht - GAP; }
    d.style.left = Math.round(Math.max(EDGE, x)) + 'px';
    d.style.top = Math.round(Math.max(EDGE, y)) + 'px';
  }

  // e is the mouse event when the pointer showed it, null for keyboard focus.
  function show(h, e) {
    var text = h.getAttribute('data-tip');
    if (!text) { return; }
    hide();
    var d = el();
    d.textContent = text;
    d.hidden = false;
    host = h;
    h.setAttribute('aria-describedby', ID);
    if (e) { placeAt(e.clientX, e.clientY, d); } else { place(h, d); }
  }

  function hide() {
    if (tip) { tip.hidden = true; }
    if (host) { host.removeAttribute('aria-describedby'); host = null; }
  }

  function target(e) {
    var t = e.target;
    return t && t.closest ? t.closest('[data-tip]') : null;
  }

  document.addEventListener('mouseover', function (e) {
    var h = target(e);
    if (h && h !== host) { show(h, e); } else if (!h && host) { hide(); }
  });
  document.addEventListener('mousemove', function (e) {
    if (host && tip && !tip.hidden) { placeAt(e.clientX, e.clientY, tip); }
  });
  document.addEventListener('mouseout', function (e) {
    if (host && !(e.relatedTarget && host.contains(e.relatedTarget))) { hide(); }
  });
  // Is the hint already on screen as the element's own label? Then keyboard focus adds
  // nothing by repeating it — and arrowing through a menu would pop a tooltip on every step.
  // The label counts only while it is whole: hidden (a collapsed sidebar's icon rail) or cut
  // by an ellipsis, the tooltip is the only place the text can be read.
  function labelled(h) {
    var l = h.querySelector('.label');
    if (!l && h.textContent.trim() === (h.getAttribute('data-tip') || '').trim()) { l = h; }
    return !!l && l.offsetParent !== null && l.scrollWidth <= l.clientWidth;
  }

  document.addEventListener('focusin', function (e) {
    var h = target(e);
    if (h && !labelled(h)) { show(h, null); }
  });
  document.addEventListener('focusout', hide);
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { hide(); } });
  window.addEventListener('scroll', hide, true);
  window.addEventListener('resize', hide);
})();
