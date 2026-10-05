# OPS: Publish LookIn landing page → GitHub Pages (gh-pages branch)

Publishes the public landing page to `gnemet.github.io/lookin` without GitHub Actions: the site is
assembled locally and pushed to the `gh-pages` branch, which GitHub Pages serves as a branch source.
Spec: `docs/specs/pages-publish-pf/`.

Run from the lookin repo root:
`../pipeline-forge/bin/pf pipelines/OPS-publish_pages.md --arg push=true`

Args: `push` (`true` publishes; anything else only assembles), `out` (assembly dir; default a fresh
temp dir). The checked-out branch is never touched — the commit is built with git plumbing.

## Flow

```
assemble → publish → done
```

## Pipeline

```yaml
name:    "OPS-publish_pages"
trigger: ops_publish_pages
tenant:  pf
```

## Step: assemble — shell

The site manifest is the `SITE` list: one `source published-path` pair per line. It is exactly what
the retired Actions workflow published. `vendor/` is taken from `git ls-files`, so untracked local
files never go public.

```yaml
config:
  interpreter: bash
  output_format: json
  params:
    OUT: "${out}"          # unset --arg arrives as the literal "{{out}}" → a fresh temp dir
  script: |
    set -eu
    SITE='landing.html index.html
    favicon.svg favicon.svg'
    case "$OUT" in ''|'{{'*) OUT="$(mktemp -d)" ;; esac
    mkdir -p "$OUT"
    find "$OUT" -mindepth 1 -delete
    printf '%s\n' "$SITE" | while read -r src dst; do
      [ -n "$src" ] || continue
      [ -f "$src" ] || { echo "missing site file: $src" >&2; exit 2; }
      cp "$src" "$OUT/$dst"
    done
    git ls-files -z vendor | while IFS= read -r -d '' f; do
      mkdir -p "$OUT/$(dirname "$f")"; cp "$f" "$OUT/$f"
    done
    : > "$OUT/.nojekyll"
    N=$(find "$OUT" -type f | wc -l)
    printf '{"out":"%s","files":%d}\n' "$OUT" "$N"
```

## Step: publish — shell

Builds a commit whose tree is exactly the assembled site (temporary index, `commit-tree`), parented
on the current remote `gh-pages` when it exists, and pushes it. Same tree as the remote → no commit.

```yaml
config:
  interpreter: bash
  params:
    OUT:  "${assemble.out}"
    PUSH: "${push}"        # only the literal "true" publishes
  script: |
    set -eu
    [ "$PUSH" = true ] || { echo "push!=true — assembled in $OUT, nothing published"; exit 0; }
    SRC=$(git rev-parse --short HEAD)
    IDX="$(mktemp -u)"
    export GIT_INDEX_FILE="$IDX"
    git --work-tree="$OUT" add -A -f .
    TREE=$(git write-tree)
    rm -f "$IDX"; unset GIT_INDEX_FILE
    PARENT=""
    if git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
      git fetch -q origin gh-pages
      PARENT=$(git rev-parse FETCH_HEAD)
      if [ "$(git rev-parse "$PARENT^{tree}")" = "$TREE" ]; then
        echo "unchanged — gh-pages already matches main@$SRC"; exit 0
      fi
    fi
    if [ -n "$PARENT" ]; then
      C=$(git commit-tree "$TREE" -p "$PARENT" -m "publish: landing page from main@$SRC")
    else
      C=$(git commit-tree "$TREE" -m "publish: landing page from main@$SRC")
    fi
    git push -q origin "$C:refs/heads/gh-pages"
    echo "published gh-pages $(git rev-parse --short "$C") from main@$SRC"
```

## Step: done — log

```yaml
config:
  message: "OPS-publish_pages: ${assemble.files} files assembled in ${assemble.out}; ${publish.stdout}"
```
