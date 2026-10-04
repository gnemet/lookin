# themed-tooltip-rollout (lookin leg) — Audit

## Verification (AI, 2026-10-04)

Pending — recorded by the conversion commit.

## Residual risk and open items

- **Not walked in a browser.**
- **`jirada-dev-method.html` still carries eight native tooltips** on its navigation buttons. It is generated; the fix belongs to the foundation-ui deck engine and a rebuild of the deck. Owner: the `themed-tooltip-rollout` item's foundation-ui leg.
- **Stacking.** The floor rule's `z-index` is 1000; lookin's document panel and modal sit at 1500 and 2000. A hint on a control inside those overlays would render underneath. No converted control is inside one today. The rule is kept byte-identical rather than adjusted.
- **Byte-identity is checked by hand** (`diff` against the floor's file at copy time); the check script pins the script's contract, not its bytes.
- The check is not wired into CI or a hook; it is run by hand.

## Acceptance (A9)

- Diff review: open — owner.
- Hover walk on every theme (pointer, keyboard focus, Escape): open — owner. Not done in this
  session; no browser walk was run.
