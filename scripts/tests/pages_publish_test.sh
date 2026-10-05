#!/usr/bin/env bash
# pages_publish_test.sh — T1 tests for the pipeline-forge GitHub Pages publish (PT1–PT4)
# Kind: test
# Spec: docs/specs/pages-publish-pf/
#
# Usage:
#   scripts/tests/pages_publish_test.sh
#
# What:   PT1 runs OPS-publish_pages with push=false into a temp dir and checks the exact file set.
#         PT2/PT3 run it with push=true in a throwaway clone whose origin is a local bare repo, and
#         check the gh-pages tree, then that a second run adds no commit. PT4 checks that no GitHub
#         Actions workflow publishes Pages. Prints PASS/FAIL per test; exit 1 on any FAIL.
# Why:    a test, not a pipeline — it exercises the pipeline from outside.
# Writes: temp dirs only (removed on exit); never this checkout's branches or its origin.
# Needs:  bin/pf (PF_BIN, else ../pipeline-forge/bin/pf, else pf on PATH), git.
# See:    pipelines/OPS-publish_pages.md · docs/specs/pages-publish-pf/tests.md
set -uo pipefail
[ "${1:-}" = "--help" ] && { sed -n '2,/^set /p' "$0" | sed '$d; s/^# \{0,1\}//'; exit 0; }

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PF="${PF_BIN:-}"
[ -z "$PF" ] && [ -x "$REPO/../pipeline-forge/bin/pf" ] && PF="$REPO/../pipeline-forge/bin/pf"
[ -z "$PF" ] && PF="$(command -v pf || true)"
[ -x "$PF" ] || { echo "FAIL setup: no pf binary"; exit 1; }
PIPE=pipelines/OPS-publish_pages.md
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fails=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; fails=$((fails+1)); }

# expected file set: index.html, favicon.svg, .nojekyll + tracked vendor/ files
expected() { { printf '%s\n' index.html favicon.svg .nojekyll; git -C "$REPO" ls-files vendor; } | sort; }
want_n=$(expected | wc -l)

# ── PT1: push=false assembles exactly the site ──────────────────────────────
OUT="$TMP/out"
if [ ! -f "$REPO/$PIPE" ]; then fail PT1 "no $PIPE"
else
  (cd "$REPO" && "$PF" --no-checkpoint --arg push=false --arg out="$OUT" "$PIPE" >"$TMP/pt1.log" 2>&1)
  got=$(cd "$OUT" 2>/dev/null && find . -type f | sed 's#^\./##' | sort)
  if [ "$got" != "$(expected)" ]; then fail PT1 "file set differs (got $(printf '%s' "$got" | grep -c .) want $want_n)"
  elif ! cmp -s "$OUT/index.html" "$REPO/landing.html"; then fail PT1 "index.html != landing.html"
  else pass "PT1 ($want_n files, index.html == landing.html)"; fi
fi

# ── PT2/PT3: push=true into a throwaway clone with a local bare origin ──────
BARE="$TMP/origin.git"; CL="$TMP/clone"
git init -q --bare "$BARE"
git clone -q "$REPO" "$CL" && git -C "$CL" remote set-url origin "$BARE"
[ -f "$REPO/$PIPE" ] && cp "$REPO/$PIPE" "$CL/$PIPE"
if [ ! -f "$CL/$PIPE" ]; then fail PT2 "no $PIPE"; fail PT3 "no $PIPE"
else
  (cd "$CL" && "$PF" --no-checkpoint --arg push=true "$PIPE" >"$TMP/pt2.log" 2>&1)
  tree=$(git -C "$BARE" ls-tree -r --name-only gh-pages 2>/dev/null | sort)
  if [ "$tree" = "$(expected)" ]; then pass "PT2 (origin/gh-pages has $want_n files)"
  else fail PT2 "origin/gh-pages tree differs (got $(printf '%s' "$tree" | grep -c .) want $want_n)"; fi
  before=$(git -C "$BARE" rev-list --count gh-pages 2>/dev/null || echo 0)
  (cd "$CL" && "$PF" --no-checkpoint --arg push=true "$PIPE" >"$TMP/pt3.log" 2>&1)
  after=$(git -C "$BARE" rev-list --count gh-pages 2>/dev/null || echo 0)
  if [ "$before" = 1 ] && [ "$after" = 1 ] && grep -q unchanged "$TMP/pt3.log"; then pass "PT3 (1 commit after 2 runs, unchanged reported)"
  else fail PT3 "commits before=$before after=$after, unchanged reported=$(grep -c unchanged "$TMP/pt3.log")"; fi
fi

# ── PT4: no Actions workflow publishes Pages ────────────────────────────────
hits=$(grep -lE "deploy-pages|upload-pages-artifact|configure-pages" "$REPO"/.github/workflows/* 2>/dev/null | wc -l)
[ "$hits" -eq 0 ] && pass "PT4 (0 Pages workflows)" || fail PT4 "$hits Pages workflow(s) in .github/workflows/"

[ "$fails" -eq 0 ] && echo "ALL PASS" || { echo "$fails FAILED"; exit 1; }
