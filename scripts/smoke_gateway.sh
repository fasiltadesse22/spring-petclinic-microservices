#!/usr/bin/env bash
# CI-only bounded real gateway -> Customers HTTP smoke. No Docker, GenAI or cloud resources.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
LOG="$(mktemp)"
RESPONSE="$(mktemp)"
cleanup(){
 bash scripts/stop_all.sh || true
 rm -f "$LOG" "$RESPONSE"
}
trap cleanup EXIT
echo "GATEWAY-SMOKE source=$(git rev-parse HEAD)"
if ! PETCLINIC_READINESS_TIMEOUT=35 timeout 210 bash scripts/run_all.sh --no-infra >"$LOG" 2>&1;then
 echo 'FAILED: application startup/readiness; last diagnostic lines follow' >&2
 tail -n 80 "$LOG" >&2
 exit 1
fi
echo 'VERIFIED: seven actual JVM application processes reported their health endpoints as ready'
deadline=$((SECONDS+75))
while ((SECONDS<deadline));do
 if curl -fsS --max-time 5 "http://127.0.0.1:8080/api/customer/owners" >"$RESPONSE";then
  if python3 -c 'import json,sys; x=json.load(open(sys.argv[1])); sys.exit(0 if isinstance(x,list) else 1)' "$RESPONSE";then
   echo 'VERIFIED: real gateway routed HTTP GET /api/customer/owners through discovery to Customers'
   echo 'VERIFIED: HTTP response parsed as JSON array; no customer payload printed'
   exit 0
  fi
 fi
 sleep 3
done
echo 'FAILED: gateway -> Customers representative GET did not return expected JSON list' >&2
tail -n 100 "$LOG" >&2
exit 2
