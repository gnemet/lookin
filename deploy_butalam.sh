#!/bin/bash
# deploy_butalam.sh — Deploy LookIn to butalam (jiramntr rsync pattern)
# LookIn is 100% static → deploy to /opt/lookin/, symlink into any project
set -e

SSH_KEY="$HOME/.ssh/butala"
TARGET="nemetg@sys-butalam01"
DEST="/opt/lookin"
SRC="$(cd "$(dirname "$0")" && pwd)"

# ── Projects that want LookIn as a documentation page ──────────
# Format: "static_dir  url_path"
# Add a line for any new project that wants to serve LookIn
SYMLINK_TARGETS=(
    "/opt/jiramntr/ui        /ui/lookin/"         # http://butalam:8080/ui/lookin/
    "/opt/johanna/ui/static  /static/lookin/"      # http://butalam:8082/static/lookin/
    # "/opt/newproject/public  /public/lookin/"     # ← just add a line
)

echo "🔭 Deploying LookIn to butalam..."

# 1. Ensure target directory exists
ssh -i "$SSH_KEY" "$TARGET" "mkdir -p $DEST"

# 2. Sync all static files
echo "Syncing core files..."
rsync -az -e "ssh -i $SSH_KEY" \
    "$SRC/index.html" "$SRC/app.js" "$SRC/style.css" \
    "$SRC/favicon.svg" \
    "$TARGET:$DEST/"

echo "Syncing configs..."
rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/configs/" "$TARGET:$DEST/configs/"

echo "Syncing vendor..."
rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/vendor/" "$TARGET:$DEST/vendor/"

echo "Syncing layers..."
rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/layers/" "$TARGET:$DEST/layers/"

echo "Syncing catalogs..."
rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/catalogs/" "$TARGET:$DEST/catalogs/"

echo "Syncing docs..."
rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/docs/" "$TARGET:$DEST/docs/"

# 3. Create symlinks for each registered project (sudo for dirs owned by other users)
echo "Creating symlinks..."
REMOTE_PWD=$(grep "^REMOTE_PWD=" "$SRC/../jiramntr/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || true)
for entry in "${SYMLINK_TARGETS[@]}"; do
    static_dir=$(echo "$entry" | awk '{print $1}')
    url_path=$(echo "$entry" | awk '{print $2}')
    project=$(basename "$(dirname "$static_dir")")

    ssh -i "$SSH_KEY" "$TARGET" "
        if [ -d $static_dir ]; then
            ln -sfn $DEST $static_dir/lookin 2>/dev/null || \
            echo '$REMOTE_PWD' | sudo -S ln -sfn $DEST $static_dir/lookin 2>/dev/null || true
            echo '  ✓ $project: $url_path → $DEST'
        else
            echo '  ⚠ $project: $static_dir not found, skipping'
        fi
    "
done

# 4. Kill any leftover Python server (no longer needed)
ssh -i "$SSH_KEY" "$TARGET" "pkill -f 'python3.*8081' 2>/dev/null || true"

echo ""
echo "✅ LookIn deployed to $TARGET:$DEST/"
echo "   Registered projects:"
for entry in "${SYMLINK_TARGETS[@]}"; do
    url_path=$(echo "$entry" | awk '{print $2}')
    echo "     → $url_path"
done
