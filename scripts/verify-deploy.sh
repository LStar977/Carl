#!/usr/bin/env bash
# End-to-end check of a deployed Carl backend.
#   Usage:  BASE="https://your-deployment-url" ./scripts/verify-deploy.sh
# Needs: curl + jq  (brew install jq)
set -uo pipefail

BASE="${BASE:-http://localhost:8787}"
command -v jq >/dev/null || { echo "This script needs jq (brew install jq)"; exit 1; }

pass=0; fail=0
check(){ # name, condition, context-on-fail
  if eval "$2"; then echo "  ✓ $1"; pass=$((pass+1));
  else echo "  ✗ $1"; [ -n "${3:-}" ] && echo "      $3"; fail=$((fail+1)); fi
}
num(){ local v; v=$(jq -r "$1 // 0" <<<"$2"); [[ "$v" =~ ^[0-9]+$ ]] && echo "$v" || echo 0; }

echo "Carl deploy check → $BASE"
echo

echo "Health & integrations"
H=$(curl -s "$BASE/health")
check "health ok"            '[ "$(jq -r .ok <<<"$H")" = "true" ]'                 "$H"
check "ats integration on"   '[ "$(jq -r .integrations.ats <<<"$H")" = "true" ]'   "$H"
echo "    llm=$(jq -r .integrations.llm <<<"$H")  usajobs=$(jq -r .integrations.usajobs <<<"$H")  applyMode=$(jq -r .applyMode <<<"$H")"

echo "Auth & intake"
TOKEN=$(curl -s -X POST "$BASE/v1/auth/anon" | jq -r .token)
check "auth returns a token" '[ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]' "no token"
AUTH=(-H "x-carl-token: $TOKEN" -H "content-type: application/json")
curl -s -X PUT "$BASE/v1/profile" "${AUTH[@]}" \
  -d '{"prefs":{"titles":["Product Designer"],"locationType":"remote","payFloor":120,"country":"us"}}' >/dev/null
R=$(curl -s -X POST "$BASE/v1/resume" "${AUTH[@]}" \
  -d '{"text":"Senior Product Designer, 6 years. Skills: Figma, Design Systems, Prototyping. jane@example.com"}')
check "résumé parsed"        '[ -n "$(jq -r ".parsed.targetRole // empty" <<<"$R")" ]' "$R"

echo "Search & queue"
S=$(curl -s -X POST "$BASE/v1/search" "${AUTH[@]}" -d '{}')
CNT=$(num .count "$S")
check "search returns jobs"  '[ "$CNT" -gt 0 ]' "$S"
echo "    found $CNT jobs · sources: $(jq -rc '.sources|map(.name)' <<<"$S" 2>/dev/null)"
Q=$(curl -s "$BASE/v1/queue" "${AUTH[@]}")
check "queue has prepared items"      '[ "$(num ".items|length" "$Q")" -gt 0 ]' "$Q"
check "queue item has a cover note"   '[ -n "$(jq -r ".items[0].draft.coverNote // empty" <<<"$Q")" ]' "$Q"
MID=$(jq -r ".items[0].matchId" <<<"$Q")

echo "Apply (assisted)"
C=$(curl -s -X POST "$BASE/v1/applications/$MID/confirm" "${AUTH[@]}" -d '{}')
check "confirm submits"               '[ "$(jq -r .submitted <<<"$C")" = "true" ]' "$C"
check "confirm returns an apply URL"  '[ -n "$(jq -r ".applyUrl // empty" <<<"$C")" ]' "$C"
echo "    credits now $(jq -r .credits <<<"$C")"
D=$(curl -s "$BASE/v1/dashboard" "${AUTH[@]}")
check "dashboard counts it"           '[ "$(num .totalApplied "$D")" -ge 1 ]' "$D"

echo "Find more"
M=$(curl -s -X POST "$BASE/v1/search/more" "${AUTH[@]}")
check "search/more returns a count"   '[ "$(jq -r ".found // \"x\"" <<<"$M")" != "x" ]' "$M"

echo "Purchase (only if APPSTORE_VERIFY=off)"
P=$(curl -s -X POST "$BASE/v1/credits/purchase" "${AUTH[@]}" -d '{"packId":"popular"}')
if [ "$(jq -r .ok <<<"$P")" = "true" ]; then
  check "purchase grants 110 credits"  '[ "$(num .granted "$P")" -eq 110 ]' "$P"
else
  echo "    • purchase needs a real receipt (APPSTORE_VERIFY=on) — expected on prod, skipping"
fi

echo
echo "─────────────────────────────────────────"
echo "PERSISTENCE CHECK (proves Postgres is working):"
echo "  1) note this token:  $TOKEN"
echo "  2) restart / redeploy the backend on Replit"
echo "  3) run:  curl -s $BASE/v1/credits -H 'x-carl-token: $TOKEN' | jq"
echo "     → the balance should still be there. If it 401s or resets, Postgres isn't wired."
echo "─────────────────────────────────────────"
echo
echo "$pass passed, $fail failed"
exit $(( fail > 0 ? 1 : 0 ))
