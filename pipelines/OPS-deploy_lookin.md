# OPS: Deploy LookIn (static) → butalam

LookIn is 100 % static — no build step, ever. Deploy the static assets to
`/opt/lookin/`, then symlink that directory into each project that wants to serve
LookIn as a documentation page.

Runs from the lookin repo root. Connection is driven entirely by env vars — set
them in the environment or via the `deploy_butalam.sh` shim before calling.

Required env vars (set by the shim or CI):
- `DEPLOY_HOST`       — SSH hostname (e.g. `sys-butalam01`)
- `DEPLOY_USER`       — SSH username (e.g. `nemetg`)
- `DEPLOY_KEY`        — path to SSH private key (e.g. `~/.ssh/butala`)
- `DEPLOY_DIR`        — remote deploy root (e.g. `/opt/lookin`)
- `DEPLOY_RSYNC_HOST` — rsync host spec including user (e.g. `nemetg@sys-butalam01`)

The per-project symlink targets live as **data** in the `link_targets` step below
(was a hardcoded Bash array). Add a project by adding one object to that JSON list.

## Flow

```
ensure_dir → sync_core → sync_configs → sync_vendor → sync_layers
  → sync_catalogs → sync_docs → link_targets → cleanup → done
```

## Pipeline

```yaml
name:    "OPS-deploy_lookin"
code:    OPS-deploy-lookin
trigger: manual
description: |
  Deploy static LookIn assets to ${DEPLOY_DIR} and symlink into registered
  projects. No build step (A: lookin must stay static). Connection from env vars.
```

## Step: ensure_dir — ssh

```yaml
config:
  host:    "${DEPLOY_HOST}"
  user:    "${DEPLOY_USER}"
  key:     "${DEPLOY_KEY}"
  command: "mkdir -p ${DEPLOY_DIR}"
```

## Step: sync_core — rsync

The four root files; no `--delete` (it would wipe the sibling subdirectories).

```yaml
config:
  src:  ["index.html", "app.js", "style.css", "favicon.svg"]
  dest: "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/"
  key:  "${DEPLOY_KEY}"
```

## Step: sync_configs — rsync

```yaml
config:
  src:    "configs/"
  dest:   "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/configs/"
  key:    "${DEPLOY_KEY}"
  delete: true
```

## Step: sync_vendor — rsync

```yaml
config:
  src:    "vendor/"
  dest:   "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/vendor/"
  key:    "${DEPLOY_KEY}"
  delete: true
```

## Step: sync_layers — rsync

```yaml
config:
  src:    "layers/"
  dest:   "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/layers/"
  key:    "${DEPLOY_KEY}"
  delete: true
```

## Step: sync_catalogs — rsync

```yaml
config:
  src:    "catalogs/"
  dest:   "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/catalogs/"
  key:    "${DEPLOY_KEY}"
  delete: true
```

## Step: sync_docs — rsync

```yaml
config:
  src:    "docs/"
  dest:   "${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/docs/"
  key:    "${DEPLOY_KEY}"
  delete: true
```

## Step: link_targets — foreach

Projects that serve LookIn as a documentation page. `static_dir` is the project's
web-served directory on the target; the symlink `<static_dir>/lookin` → `${DEPLOY_DIR}`
exposes LookIn at `url_path`. Add a project by appending one object here.

```yaml
config:
  items: |
    [
      {"project": "jiramntr", "static_dir": "/opt/jiramntr/ui",        "url_path": "/ui/lookin/"},
      {"project": "johanna",  "static_dir": "/opt/johanna/ui/static",  "url_path": "/static/lookin/"}
    ]
  as: target
foreach:
  - link_one
```

## Step: link_one — ssh

Create (or refresh) the symlink if the project's static dir exists. Falls back to
`sudo ln` for directories owned by another user (requires NOPASSWD: /usr/bin/ln),
and never fails the deploy if a target is absent.

```yaml
config:
  host:    "${DEPLOY_HOST}"
  user:    "${DEPLOY_USER}"
  key:     "${DEPLOY_KEY}"
  command: |
    if [ -d "${target.static_dir}" ]; then
      ln -sfn ${DEPLOY_DIR} ${target.static_dir}/lookin 2>/dev/null || \
      sudo ln -sfn ${DEPLOY_DIR} ${target.static_dir}/lookin 2>/dev/null || true
      echo "  ok ${target.project}: ${target.url_path} -> ${DEPLOY_DIR}"
    else
      echo "  skip ${target.project}: ${target.static_dir} not found"
    fi
```

## Step: cleanup — ssh

Kill any leftover standalone Python preview server (port 8081) — no longer needed
now that LookIn is served as static files behind each project.

```yaml
config:
  host:    "${DEPLOY_HOST}"
  user:    "${DEPLOY_USER}"
  key:     "${DEPLOY_KEY}"
  command: "pkill -f 'python3.*8081' 2>/dev/null || true"
```

## Step: done — log

```yaml
config:
  message: "✓ LookIn deployed to ${DEPLOY_RSYNC_HOST}:${DEPLOY_DIR}/ (links: ${link_targets.total}, ok: ${link_targets.sent})"
```
