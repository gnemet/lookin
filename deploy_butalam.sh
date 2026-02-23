#!/bin/bash
# Deploy LookIn to butalam (offline environment)
# Uses local vendor/ for all JS/CSS/font dependencies
set -e

SSH="ssh -i ~/.ssh/butala nemetg@sys-butalam01"
SCP="scp -i ~/.ssh/butala"
DEST="/opt/lookin"
SRC="$(cd "$(dirname "$0")" && pwd)"

echo "🔭 Deploying LookIn to butalam..."

# 1. Copy core files
$SCP "$SRC/app.js" "$SRC/style.css" "$SRC/lookin.yaml" "$SRC/favicon.svg" nemetg@sys-butalam01:$DEST/

# 2. Copy vendor (offline dependencies)
$SSH "mkdir -p $DEST/vendor/fonts"
$SCP $SRC/vendor/*.js $SRC/vendor/*.css nemetg@sys-butalam01:$DEST/vendor/
$SCP $SRC/vendor/Phosphor.* nemetg@sys-butalam01:$DEST/vendor/
$SCP $SRC/vendor/fonts/* nemetg@sys-butalam01:$DEST/vendor/fonts/

# 3. Copy layers + catalogs
$SSH "mkdir -p $DEST/layers $DEST/catalogs"
$SCP $SRC/layers/*.mmd nemetg@sys-butalam01:$DEST/layers/
$SCP $SRC/catalogs/*.json nemetg@sys-butalam01:$DEST/catalogs/

# 4. Copy docs if they exist
if [ -d "$SRC/docs" ]; then
    $SSH "mkdir -p $DEST/docs"
    $SCP -r $SRC/docs/* nemetg@sys-butalam01:$DEST/docs/
fi

# 5. Generate offline index.html (swap CDN → vendor/)
sed \
    -e 's|https://cdn.jsdelivr.net/npm/@phosphor-icons/web@2.1.1/src/regular/style.css|vendor/phosphor-icons.css|' \
    -e 's|https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js|vendor/js-yaml.min.js|' \
    -e 's|https://cdn.jsdelivr.net/npm/marked/marked.min.js|vendor/marked.min.js|' \
    -e 's|<script type="module">|<script>|' \
    -e "s|import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';|// mermaid loaded via vendor/mermaid.min.js|" \
    -e 's|window.mermaidLib = mermaid;|window.mermaidLib = window.mermaid;|' \
    "$SRC/index.html" > /tmp/lookin_index.html
$SCP /tmp/lookin_index.html nemetg@sys-butalam01:$DEST/index.html

# 6. Copy mermaid UMD bundle (must load BEFORE the inline script)
# Insert mermaid script tag before js-yaml
$SSH "cd $DEST && sed -i 's|vendor/js-yaml.min.js|vendor/mermaid.min.js\"></script>\n    <script src=\"vendor/js-yaml.min.js|' index.html"

# 7. Generate offline style.css (swap Google Fonts → local @font-face)
$SSH "cd $DEST && sed -i \"s|@import url('https://fonts.googleapis.com/css2?family=Caveat:wght@400;600\&family=Inter:wght@300;400;500;600;700\&display=swap');|/* Local fonts */\n@font-face { font-family: 'Caveat'; font-weight: 400; src: url('vendor/fonts/Caveat-Regular.ttf') format('truetype'); }\n@font-face { font-family: 'Caveat'; font-weight: 600; src: url('vendor/fonts/Caveat-SemiBold.ttf') format('truetype'); }\n@font-face { font-family: 'Inter'; font-weight: 400; src: url('vendor/fonts/Inter-Regular.woff2'); }\n@font-face { font-family: 'Inter'; font-weight: 600; src: url('vendor/fonts/Inter-SemiBold.woff2'); }\n@font-face { font-family: 'Inter'; font-weight: 700; src: url('vendor/fonts/Inter-Bold.woff2'); }|\" style.css"

# 8. Restart server
$SSH "pkill -f 'python3.*8081' 2>/dev/null; sleep 1; cd $DEST && nohup python3 -m http.server 8081 > /tmp/lookin.log 2>&1 & echo \"LookIn deployed on port 8081, PID: \$!\""

echo "✅ LookIn deployed to http://sys-butalam01:8081"
