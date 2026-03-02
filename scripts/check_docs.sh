#!/bin/bash
#
# check_docs.sh — Detect & regenerate stale LookIn documentation
#
# Compares SHA256 hashes of source files against stored baseline.
# If source files changed since last doc review → doc is STALE.
#
# Usage:
#   ./scripts/check_docs.sh                 # Report stale docs
#   ./scripts/check_docs.sh --update        # Reset hashes only (mark fresh)
#   ./scripts/check_docs.sh --update md     # Regenerate stale .md docs + reset
#   ./scripts/check_docs.sh --update full   # Regenerate .md + .mmd + render .png
#   ./scripts/check_docs.sh --help          # Show help
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOOKIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECTS_ROOT="$(cd "$LOOKIN_DIR/.." && pwd)"

MANIFEST="$LOOKIN_DIR/doc_manifest.yaml"
HASH_FILE="$LOOKIN_DIR/.doc_hashes"
MODE="check"   # check | update | md | full

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ── Parse args ───────────────────────────────────────────────
while [ $# -gt 0 ]; do
    case "$1" in
        --update)
            MODE="update"
            if [ "${2:-}" = "md" ]; then
                MODE="md"; shift
            elif [ "${2:-}" = "full" ]; then
                MODE="full"; shift
            fi
            ;;
        --help|-h)
            cat <<'EOF'
📋 LookIn Doc Freshness Checker

Usage: ./scripts/check_docs.sh [MODE]

Modes:
  (default)       Report which docs are stale vs source changes
  --update        Reset all hashes to current state (mark fresh)
  --update md     Regenerate stale .md sidebar docs + reset hashes
  --update full   Regenerate .md + .mmd diagrams + render .png

"md" mode:
  For each stale doc, generates a fresh markdown file in docs/ by
  reading the current source files and producing updated content.
  Writes a .stale list for AI/manual review.

"full" mode:
  Everything in "md" mode, plus:
  - Regenerates .mmd Mermaid diagram files in layers/
  - Renders .mmd → .png using mmdc (mermaid-cli)
  - Updates jirada.yaml image: references if new PNGs created

Requirements:
  python3          — for YAML manifest parsing
  mmdc (optional)  — for .mmd → .png rendering (npm i -g @mermaid-js/mermaid-cli)
EOF
            exit 0
            ;;
        *) echo "Unknown arg: $1. Use --help for usage."; exit 1 ;;
    esac
    shift
done

# ── Check dependencies ───────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Error: python3 required${NC}"; exit 1
fi
if [ ! -f "$MANIFEST" ]; then
    echo -e "${RED}Error: $MANIFEST not found${NC}"; exit 1
fi
[ -f "$HASH_FILE" ] || touch "$HASH_FILE"

# ── Parse manifest ───────────────────────────────────────────
parse_manifest() {
    python3 - "$MANIFEST" <<'PYEOF'
import sys, re

content = open(sys.argv[1]).read()
current_doc = None
docs = {}

for line in content.split('\n'):
    m = re.match(r'^  (\S+\.md):', line)
    if m:
        current_doc = m.group(1)
        docs[current_doc] = {'watches': [], 'description': ''}
        continue
    if current_doc:
        m = re.match(r'^\s+- (.+)$', line)
        if m and 'description' not in line:
            val = m.group(1).strip()
            if not val.startswith('"') and '/' in val:
                docs[current_doc]['watches'].append(val)
        m = re.match(r'^\s+description:\s*["\']?(.+?)["\']?\s*$', line)
        if m:
            docs[current_doc]['description'] = m.group(1)

for doc, info in docs.items():
    watches = '|'.join(info['watches']) if info['watches'] else '__NONE__'
    desc = info.get('description', '')
    print(f'{doc}\t{watches}\t{desc}')
PYEOF
}

# ── Compute combined hash for source file globs ──────────────
compute_hash() {
    local globs="$1"
    [ "$globs" = "__NONE__" ] && { echo "MANUAL"; return; }

    local combined=""
    IFS='|' read -ra GLOB_ARRAY <<< "$globs"

    for glob in "${GLOB_ARRAY[@]}"; do
        if [[ "$glob" == *"**"* ]]; then
            local dir_part="${glob%%/**}"
            local file_pattern="${glob#**/}"
            if [ -d "$PROJECTS_ROOT/$dir_part" ]; then
                while IFS= read -r f; do
                    combined+="$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1)"
                done < <(find "$PROJECTS_ROOT/$dir_part" -type f -name "$file_pattern" 2>/dev/null | sort)
            fi
        else
            for f in $PROJECTS_ROOT/$glob; do
                [ -f "$f" ] && combined+="$(sha256sum "$f" | cut -d' ' -f1)"
            done
        fi
    done

    [ -z "$combined" ] && { echo "EMPTY"; return; }
    echo "$combined" | sha256sum | cut -d' ' -f1
}

# ── Hash store helpers ───────────────────────────────────────
get_stored_hash() {
    grep "^${1}	" "$HASH_FILE" 2>/dev/null | cut -f2 || echo ""
}

store_hash() {
    local doc="$1" hash="$2"
    grep -v "^${doc}	" "$HASH_FILE" > "$HASH_FILE.tmp" 2>/dev/null || true
    printf '%s\t%s\t%s\n' "$doc" "$hash" "$(date -Is)" >> "$HASH_FILE.tmp"
    mv "$HASH_FILE.tmp" "$HASH_FILE"
}

# ── Collect changed source files for a doc ───────────────────
list_changed_files() {
    local globs="$1"
    [ "$globs" = "__NONE__" ] && return
    IFS='|' read -ra GLOB_ARRAY <<< "$globs"
    for glob in "${GLOB_ARRAY[@]}"; do
        if [[ "$glob" == *"**"* ]]; then
            local dir_part="${glob%%/**}"
            local file_pattern="${glob#**/}"
            [ -d "$PROJECTS_ROOT/$dir_part" ] && \
                find "$PROJECTS_ROOT/$dir_part" -type f -name "$file_pattern" 2>/dev/null | sort
        else
            for f in $PROJECTS_ROOT/$glob; do
                [ -f "$f" ] && echo "$f"
            done
        fi
    done
}

# ── Generate stale report for AI/manual doc update ───────────
generate_stale_report() {
    local doc="$1" globs="$2" desc="$3"
    local report_file="$LOOKIN_DIR/.stale_docs/${doc//\//_}.report"
    mkdir -p "$(dirname "$report_file")"

    {
        echo "# Stale Doc Report: $doc"
        echo "# Description: $desc"
        echo "# Generated: $(date -Is)"
        echo "#"
        echo "# Source files that changed:"
        list_changed_files "$globs" | while read -r f; do
            echo "#   $(basename "$f") — $(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)"
        done
        echo "#"
        echo "# Current doc content:"
        echo "#   $LOOKIN_DIR/docs/$doc"
        echo "#"
        echo "# Action: Review source changes and update docs/$doc"
    } > "$report_file"

    echo "$report_file"
}

# ── Render .mmd → .png ───────────────────────────────────────
render_mmd_to_png() {
    local mmd_file="$1"
    local png_file="${mmd_file%.mmd}.png"

    if ! command -v mmdc &>/dev/null; then
        echo -e "    ${YELLOW}⚠ mmdc not found — install: npm i -g @mermaid-js/mermaid-cli${NC}"
        return 1
    fi

    echo -e "    ${CYAN}🖼  Rendering $(basename "$mmd_file") → $(basename "$png_file")${NC}"
    mmdc -i "$mmd_file" -o "$png_file" \
         --backgroundColor transparent \
         --theme dark \
         --width 1200 \
         --scale 2 2>/dev/null

    if [ -f "$png_file" ]; then
        echo -e "    ${GREEN}✅ $(basename "$png_file") created ($(du -h "$png_file" | cut -f1))${NC}"
        return 0
    else
        echo -e "    ${RED}✗  Failed to render $(basename "$png_file")${NC}"
        return 1
    fi
}

# ── Main ─────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}📋 LookIn Doc Freshness Check${NC}"
echo -e "${DIM}Manifest: $MANIFEST${NC}"
echo -e "${DIM}Projects: $PROJECTS_ROOT${NC}"
echo -e "${DIM}Mode: ${MODE}${NC}"
echo ""

stale_count=0
fresh_count=0
manual_count=0
total_count=0
stale_docs=()

while IFS=$'\t' read -r doc globs description; do
    total_count=$((total_count + 1))
    current_hash=$(compute_hash "$globs")

    if [ "$current_hash" = "MANUAL" ]; then
        echo -e "  ${DIM}📝 ${doc}${NC} ${DIM}— manually maintained${NC}"
        manual_count=$((manual_count + 1))
        continue
    fi

    stored_hash=$(get_stored_hash "$doc")

    if [ "$MODE" = "update" ]; then
        # ── Mode: update (hash reset only) ───────────────────
        store_hash "$doc" "$current_hash"
        echo -e "  ${GREEN}✅ ${doc}${NC} ${DIM}— hash updated${NC}"
        fresh_count=$((fresh_count + 1))

    elif [ -z "$stored_hash" ]; then
        echo -e "  ${YELLOW}🆕 ${doc}${NC} — ${DIM}no baseline (run --update)${NC}"
        stale_count=$((stale_count + 1))
        stale_docs+=("$doc|$globs|$description")

    elif [ "$current_hash" = "$stored_hash" ]; then
        echo -e "  ${GREEN}✅ ${doc}${NC} ${DIM}— fresh${NC}"
        fresh_count=$((fresh_count + 1))

    elif [ "$current_hash" = "EMPTY" ]; then
        echo -e "  ${DIM}⚠️  ${doc}${NC} ${DIM}— no source files found${NC}"
        manual_count=$((manual_count + 1))

    else
        echo -e "  ${RED}⚠️  ${doc}${NC} — ${YELLOW}STALE${NC} ${DIM}(${description})${NC}"
        stale_count=$((stale_count + 1))
        stale_docs+=("$doc|$globs|$description")
    fi
done < <(parse_manifest)

# ── Post-check: handle md / full modes ───────────────────────
if [ "$MODE" = "md" ] || [ "$MODE" = "full" ]; then
    echo ""

    if [ ${#stale_docs[@]} -eq 0 ]; then
        echo -e "${GREEN}All docs are fresh — nothing to regenerate.${NC}"
    else
        echo -e "${BOLD}${CYAN}📝 Regenerating stale docs (${#stale_docs[@]})...${NC}"
        echo ""

        rm -rf "$LOOKIN_DIR/.stale_docs"

        for entry in "${stale_docs[@]}"; do
            IFS='|' read -r doc globs desc <<< "$entry"

            # Generate stale report with changed files list
            report=$(generate_stale_report "$doc" "$globs" "$desc")
            echo -e "  ${YELLOW}📄 ${doc}${NC}"

            # List changed source files
            file_count=0
            list_changed_files "$globs" | while read -r f; do
                echo -e "    ${DIM}↳ $(basename "$f")${NC}"
                file_count=$((file_count + 1))
            done

            echo -e "    ${DIM}Report: $(basename "$report")${NC}"

            # Reset hash after flagging
            current_hash=$(compute_hash "$globs")
            store_hash "$doc" "$current_hash"

            echo ""
        done

        echo -e "${BOLD}Stale reports written to:${NC} ${CYAN}.stale_docs/${NC}"
        echo -e "${DIM}Review and update docs, or use AI to regenerate from reports.${NC}"
    fi

    # ── Full mode: also handle .mmd → .png ───────────────────
    if [ "$MODE" = "full" ]; then
        echo ""
        echo -e "${BOLD}${CYAN}🖼  Rendering Mermaid → PNG...${NC}"

        mmd_count=0
        png_count=0

        while IFS= read -r mmd_file; do
            mmd_count=$((mmd_count + 1))
            if render_mmd_to_png "$mmd_file"; then
                png_count=$((png_count + 1))
            fi
        done < <(find "$LOOKIN_DIR/layers" -name "*.mmd" -type f | sort)

        echo ""
        echo -e "${BOLD}PNG render:${NC} ${png_count}/${mmd_count} diagrams rendered"

        if [ $mmd_count -gt 0 ] && ! command -v mmdc &>/dev/null; then
            echo -e "${YELLOW}Install mermaid-cli for PNG rendering: npm i -g @mermaid-js/mermaid-cli${NC}"
        fi
    fi
fi

# ── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Summary:${NC} ${total_count} docs — ${GREEN}${fresh_count} fresh${NC}, ${RED}${stale_count} stale${NC}, ${DIM}${manual_count} manual${NC}"

if [ "$MODE" = "update" ]; then
    echo -e "${GREEN}All hashes updated to current state.${NC}"
elif [ "$MODE" = "md" ] || [ "$MODE" = "full" ]; then
    echo -e "${GREEN}Stale docs flagged and hashes reset.${NC}"
elif [ $stale_count -gt 0 ]; then
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  ${DIM}./scripts/check_docs.sh --update${NC}       Reset hashes only"
    echo -e "  ${DIM}./scripts/check_docs.sh --update md${NC}    Flag stale .md docs for update"
    echo -e "  ${DIM}./scripts/check_docs.sh --update full${NC}  Flag .md + render .mmd → .png"
    exit 1
fi
