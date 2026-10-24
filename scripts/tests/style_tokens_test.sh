#!/usr/bin/env bash
# style_tokens_test.sh — lookin's style.css repeats none of its own :root colours as a literal.
# Kind: test
# Spec: claude-base docs/audits (A1 lookin raw colour lines)
#
# Subject: style.css.
# Covers:  ST1: after the :root block, no hex literal equals a :root token's hex value, and no
#               rgba() spells out a token colour's r, g, b (use rgba(var(--<name>-rgb), a)).
#
# Usage:
#   bash scripts/tests/style_tokens_test.sh
set -uo pipefail

CSS="$(cd "$(dirname "$0")/../.." && pwd)/style.css"
root_end=$(grep -n '^}' "$CSS" | head -1 | cut -d: -f1)
fail=0

# token hex values (#rgb / #rrggbb) and their r, g, b triples
mapfile -t hexes < <(sed -n "1,${root_end}p" "$CSS" | grep -oE ':\s*#[0-9a-fA-F]{3,6}\b' | grep -oE '#[0-9a-fA-F]+' | sort -u)
body=$(sed -n "$((root_end + 1)),\$p" "$CSS")
for h in "${hexes[@]}"; do
	if grep -qiE "${h}\b" <<<"$body"; then
		printf 'FAIL ST1: %s (a :root token) written as a literal\n' "$h"; fail=1
	fi
	x=${h#\#}; [ ${#x} -eq 3 ] && x="${x:0:1}${x:0:1}${x:1:1}${x:1:1}${x:2:1}${x:2:1}"
	rgb="$((16#${x:0:2})), *$((16#${x:2:2})), *$((16#${x:4:2}))"
	if grep -qE "rgba?\(${rgb}," <<<"$body"; then
		printf 'FAIL ST1: rgba(%s, …) spells out token %s\n' "${rgb// \*/ }" "$h"; fail=1
	fi
done
[ $fail -eq 0 ] && echo 'ok   ST1: no :root colour repeated as a literal'
exit $fail
