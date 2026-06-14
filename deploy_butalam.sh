#!/bin/bash
# deploy_butalam.sh — thin shim around pipelines/OPS-deploy_lookin.md.
#
# Sets DEPLOY_* env vars for butalam and delegates to the pipeline. Falls back to
# inline bash for CI / cold-start when bin/pf is not available.
#
# LookIn is 100% static — no build step. The pipeline rsyncs the static assets to
# /opt/lookin/ and symlinks them into each registered project.
#
# Usage:
#   ./deploy_butalam.sh    # rsync static assets + refresh symlinks → OPS-deploy_lookin.md

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Deploy target config (override any of these in the environment) ───────────
export DEPLOY_HOST="${DEPLOY_HOST:-sys-butalam01}"
export DEPLOY_USER="${DEPLOY_USER:-nemetg}"
export DEPLOY_KEY="${DEPLOY_KEY:-$HOME/.ssh/butala}"
export DEPLOY_DIR="${DEPLOY_DIR:-/opt/lookin}"
export DEPLOY_RSYNC_HOST="${DEPLOY_RSYNC_HOST:-${DEPLOY_USER}@${DEPLOY_HOST}}"

# ── pf discovery ─────────────────────────────────────────────────────────────
PF_BIN="${PF_BIN:-}"
[ -z "$PF_BIN" ] && [ -x "$SCRIPT_DIR/bin/pf" ]                   && PF_BIN="$SCRIPT_DIR/bin/pf"
[ -z "$PF_BIN" ] && [ -x "$SCRIPT_DIR/../pipeline-forge/bin/pf" ] && PF_BIN="$SCRIPT_DIR/../pipeline-forge/bin/pf"
[ -z "$PF_BIN" ] && command -v pf >/dev/null 2>&1                  && PF_BIN="$(command -v pf)"

# ── Route to pipeline ─────────────────────────────────────────────────────────
if [ -n "$PF_BIN" ] && [ -x "$PF_BIN" ]; then
  exec "$PF_BIN" "$SCRIPT_DIR/pipelines/OPS-deploy_lookin.md"
fi

# ── Inline fallback (CI / cold-start) ────────────────────────────────────────
echo "▶ deploy_butalam.sh — running inline (pf not found)"

SSH_KEY="$DEPLOY_KEY"
TARGET="$DEPLOY_RSYNC_HOST"
DEST="$DEPLOY_DIR"
SRC="$SCRIPT_DIR"

# Per-project symlink targets — keep in sync with OPS-deploy_lookin.md link_targets.
SYMLINK_TARGETS=(
    "/opt/jiramntr/ui        /ui/lookin/"
    "/opt/johanna/ui/static  /static/lookin/"
)

echo "🔭 Deploying LookIn to $TARGET..."
ssh -i "$SSH_KEY" "$TARGET" "mkdir -p $DEST"

echo "Syncing core files..."
rsync -az -e "ssh -i $SSH_KEY" \
    "$SRC/index.html" "$SRC/app.js" "$SRC/style.css" "$SRC/favicon.svg" \
    "$TARGET:$DEST/"

for dir in configs vendor layers catalogs docs; do
    echo "Syncing $dir..."
    rsync -az --delete -e "ssh -i $SSH_KEY" "$SRC/$dir/" "$TARGET:$DEST/$dir/"
done

echo "Creating symlinks..."
for entry in "${SYMLINK_TARGETS[@]}"; do
    static_dir=$(echo "$entry" | awk '{print $1}')
    url_path=$(echo "$entry" | awk '{print $2}')
    project=$(basename "$(dirname "$static_dir")")
    ssh -i "$SSH_KEY" "$TARGET" "
        if [ -d $static_dir ]; then
            ln -sfn $DEST $static_dir/lookin 2>/dev/null || \
            sudo ln -sfn $DEST $static_dir/lookin 2>/dev/null || true
            echo '  ok $project: $url_path -> $DEST'
        else
            echo '  skip $project: $static_dir not found'
        fi
    "
done

ssh -i "$SSH_KEY" "$TARGET" "pkill -f 'python3.*8081' 2>/dev/null || true"
echo "✅ LookIn deployed to $TARGET:$DEST/"
