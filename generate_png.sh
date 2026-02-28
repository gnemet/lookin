#!/bin/bash
# generate_png.sh — Convert .mmd diagrams to PNG images
# Uses @mermaid-js/mermaid-cli (mmdc) with system Chrome + LookIn's handDrawn theme
#
# Usage:
#   ./generate_png.sh              # Only regenerate stale PNGs (dark bg)
#   ./generate_png.sh --force      # Force regenerate all PNGs
#   ./generate_png.sh --no-bg      # Use transparent background
#   ./generate_png.sh --force --no-bg
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
MMDC="$SRC/node_modules/.bin/mmdc"

# ── Parse flags ──────────────────────────────────────────────────
FORCE=false
BACKGROUND=true   # default: dark chalkboard background (#2a2a2a)

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=true ;;
        --no-bg)   BACKGROUND=false ;;
        --bg)      BACKGROUND=true ;;
        -h|--help)
            echo "Usage: $0 [--force] [--no-bg] [--bg]"
            echo "  --force   Regenerate all PNGs regardless of timestamps"
            echo "  --no-bg   Use transparent background (default: dark #2a2a2a)"
            echo "  --bg      Use dark chalkboard background (default)"
            exit 0
            ;;
        *) echo "Unknown flag: $arg"; exit 1 ;;
    esac
done

# ── Check Chrome ─────────────────────────────────────────────────
CHROME=$(which google-chrome || which chromium-browser || which chromium 2>/dev/null)
if [ -z "$CHROME" ]; then
    echo "❌ No Chrome/Chromium found. Install with: sudo apt install chromium-browser"
    exit 1
fi
echo "Using browser: $CHROME"

# ── Background color ─────────────────────────────────────────────
if [ "$BACKGROUND" = true ]; then
    BG_COLOR="#2a2a2a"
    echo "Background: dark chalkboard ($BG_COLOR)"
else
    BG_COLOR="transparent"
    echo "Background: transparent"
fi

# ── Mermaid config matching LookIn's chalkboard theme ────────────
CONFIG_FILE=$(mktemp /tmp/mmdc_config.XXXXXX.json)
cat > "$CONFIG_FILE" <<'EOF'
{
  "theme": "dark",
  "look": "handDrawn",
  "fontFamily": "sans-serif",
  "themeVariables": {
    "darkMode": true,
    "background": "#2a2a2a",
    "primaryColor": "#3a3a3a",
    "primaryTextColor": "#f0e6d3",
    "primaryBorderColor": "#888",
    "secondaryColor": "#333",
    "lineColor": "#ccc",
    "textColor": "#f0e6d3"
  },
  "flowchart": { "curve": "natural", "nodeSpacing": 40, "rankSpacing": 60, "padding": 15 }
}
EOF

# ── Puppeteer config: use system Chrome ──────────────────────────
PUPPETEER_CONFIG=$(mktemp /tmp/mmdc_puppet.XXXXXX.json)
cat > "$PUPPETEER_CONFIG" <<EOF
{
  "executablePath": "$CHROME",
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
EOF

count=0
skipped=0
errors=0

echo ""
echo "🔭 Generating PNG images from .mmd diagrams..."
if [ "$FORCE" = true ]; then
    echo "   (--force: regenerating ALL)"
fi
echo ""

for mmd in $(find "$SRC/layers" -name "*.mmd" | sort); do
    relpath="${mmd#$SRC/}"
    pngpath="${mmd%.mmd}.png"
    relout="${pngpath#$SRC/}"

    # ── Freshness check: skip if PNG is newer than MMD ───────────
    if [ "$FORCE" = false ] && [ -f "$pngpath" ] && [ "$pngpath" -nt "$mmd" ]; then
        skipped=$((skipped + 1))
        echo "  ⏭️  $relpath (up-to-date)"
        continue
    fi

    echo -n "  📐 $relpath → $relout ... "

    if $MMDC -i "$mmd" -o "$pngpath" -c "$CONFIG_FILE" -p "$PUPPETEER_CONFIG" \
        -b "$BG_COLOR" -w 2560 -s 3 2>/tmp/mmdc_err.log; then
        echo "✅ ($(du -h "$pngpath" | cut -f1))"
        count=$((count + 1))
    else
        echo "❌ $(tail -1 /tmp/mmdc_err.log)"
        errors=$((errors + 1))
    fi
done

rm -f "$CONFIG_FILE" "$PUPPETEER_CONFIG"

echo ""
echo "Done! Generated $count, skipped $skipped up-to-date, $errors errors"
