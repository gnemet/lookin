#!/bin/bash
# setup_vendor.sh — Download vendor dependencies for offline/LAN deployment
# Run this once on each machine that needs to serve LookIn without internet access.
#
# Usage:
#   ./setup_vendor.sh          # Download vendor files
#   ./setup_vendor.sh --force  # Re-download even if files exist
set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
VENDOR="$SRC/vendor"
FORCE=false

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        -h|--help)
            echo "Usage: $0 [--force]"
            echo "Downloads vendor JS/CSS/font files for offline use."
            exit 0
            ;;
    esac
done

mkdir -p "$VENDOR/fonts"

echo "🔭 LookIn — Setting up vendor dependencies for offline use"
echo ""

download() {
    local url="$1"
    local dest="$2"
    local name="$(basename "$dest")"

    if [ "$FORCE" = false ] && [ -f "$dest" ] && [ -s "$dest" ]; then
        echo "  ⏭️  $name (exists, $(du -h "$dest" | cut -f1))"
        return
    fi

    echo -n "  📥 $name ... "
    if curl -sL -o "$dest" "$url" && [ -s "$dest" ]; then
        echo "✅ ($(du -h "$dest" | cut -f1))"
    else
        echo "❌ Failed"
        rm -f "$dest"
    fi
}

echo "── Core Libraries ────────────────────────────────"
download "https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js" \
         "$VENDOR/js-yaml.min.js"

download "https://cdnjs.cloudflare.com/ajax/libs/marked/9.1.6/marked.min.js" \
         "$VENDOR/marked.min.js"

echo ""
echo "── Icons ─────────────────────────────────────────"
download "https://unpkg.com/@phosphor-icons/web@2/src/regular/style.css" \
         "$VENDOR/phosphor-icons.css"

# Phosphor icon font files
download "https://unpkg.com/@phosphor-icons/web@2/src/regular/Phosphor.woff2" \
         "$VENDOR/fonts/Phosphor.woff2"

echo ""
echo "── Fonts (Caveat + Inter) ────────────────────────"
download "https://fonts.gstatic.com/s/caveat/v18/WnznHAc5bAfYB2QRah7pcpNvOx-pjfJ9eIGpYCxBig.woff2" \
         "$VENDOR/fonts/Caveat-Regular.woff2"

download "https://fonts.gstatic.com/s/caveat/v18/WnznHAc5bAfYB2QRah7pcpNvOx-pjcZ9eIGpYCxBig.woff2" \
         "$VENDOR/fonts/Caveat-SemiBold.woff2"

download "https://fonts.gstatic.com/s/inter/v18/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuLyfAZ9hiJ-Ek-_EeA.woff2" \
         "$VENDOR/fonts/Inter-Regular.woff2"

download "https://fonts.gstatic.com/s/inter/v18/UcCO3FwrK3iLTeHuS_nVMrMxCp50SjIw2boKoduKmMEVuI6fAZ9hiJ-Ek-_EeA.woff2" \
         "$VENDOR/fonts/Inter-SemiBold.woff2"

echo ""
echo "── Optional: Mermaid (only if you need live diagram editing) ──"
echo "   Mermaid is NOT required when using pre-rendered PNGs."
echo "   To install anyway:  curl -sL -o vendor/mermaid.min.js \\"
echo "     https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"

echo ""
echo "Done! Vendor files ready for LAN deployment."
echo "Serve with: python3 -m http.server 8070"
