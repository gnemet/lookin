#!/bin/bash
# generate_png.sh — Convert all .mmd diagrams to PNG images
# Uses @mermaid-js/mermaid-cli (mmdc) with system Chrome + LookIn's handDrawn theme
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
MMDC="$SRC/node_modules/.bin/mmdc"

# Use system Chrome (skip Puppeteer's bundled Chromium download)
CHROME=$(which google-chrome || which chromium-browser || which chromium 2>/dev/null)
if [ -z "$CHROME" ]; then
    echo "❌ No Chrome/Chromium found. Install with: sudo apt install chromium-browser"
    exit 1
fi
echo "Using browser: $CHROME"

# Mermaid config matching LookIn's chalkboard theme
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

# Puppeteer config: use system Chrome
PUPPETEER_CONFIG=$(mktemp /tmp/mmdc_puppet.XXXXXX.json)
cat > "$PUPPETEER_CONFIG" <<EOF
{
  "executablePath": "$CHROME",
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
EOF

count=0
errors=0

echo ""
echo "🔭 Generating PNG images from .mmd diagrams..."
echo ""

for mmd in $(find "$SRC/layers" -name "*.mmd" | sort); do
    relpath="${mmd#$SRC/}"
    pngpath="${mmd%.mmd}.png"
    relout="${pngpath#$SRC/}"

    echo -n "  📐 $relpath → $relout ... "

    if $MMDC -i "$mmd" -o "$pngpath" -c "$CONFIG_FILE" -p "$PUPPETEER_CONFIG" \
        -b "#2a2a2a" -w 2560 -s 3 2>/tmp/mmdc_err.log; then
        echo "✅ ($(du -h "$pngpath" | cut -f1))"
        count=$((count + 1))
    else
        echo "❌ $(tail -1 /tmp/mmdc_err.log)"
        errors=$((errors + 1))
    fi
done

rm -f "$CONFIG_FILE" "$PUPPETEER_CONFIG"

echo ""
echo "Done! Generated $count PNG files ($errors errors)"
