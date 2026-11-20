#!/usr/bin/env bash
# Safe fake-Java and fake-curl readiness contract tests; CI checkout only.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TMP="$(mktemp -d)"
STATE="$ROOT/target/local-supervisor"
APP=(config-server discovery-server customers-service visits-service vets-service api-gateway admin-server)
cleanup(){
  "$ROOT/scripts/stop_all.sh" >/dev/null 2>&1 || true
  rm -rf "$TMP"
  for name in "${APP[@]}";do rm -f "$ROOT/spring-petclinic-$name/target/owned-test.jar";done
}
trap cleanup EXIT
cat > "$TMP/java" <<'PY'
#!/usr/bin/env python3
import os,sys,time
if os.getenv("PETCLINIC_FAKE_JAVA_EXIT")=="1":sys.exit(23)
time.sleep(55)
PY
cat > "$TMP/curl" <<'SH'
#!/bin/sh
[ "${PETCLINIC_FAKE_HEALTH:-fail}" = pass ]
SH
chmod +x "$TMP/java" "$TMP/curl"
for name in "${APP[@]}";do
 mkdir -p "$ROOT/spring-petclinic-$name/target"
 printf 'fake jar, not a real application\n' > "$ROOT/spring-petclinic-$name/target/owned-test.jar"
done
export PATH="$TMP:$PATH" PETCLINIC_READINESS_TIMEOUT=2 PETCLINIC_COMPOSE_PROJECT=petclinic-ci-test
echo '=== Negative readiness: fake endpoint never healthy ==='
if PETCLINIC_FAKE_HEALTH=fail "$ROOT/scripts/run_all.sh" --no-infra >"$TMP/failure.log" 2>&1;then
 echo "ERROR: unhealthy startup returned success" >&2;exit 1
fi
grep -q 'FAILED: config-server not healthy' "$TMP/failure.log"
test ! -e "$STATE/config-server.json"
echo 'PASS: readiness timeout failed and owned service cleaned'
echo '=== Positive readiness and owned teardown ==='
PETCLINIC_FAKE_HEALTH=pass "$ROOT/scripts/run_all.sh" --no-infra >"$TMP/success.log" 2>&1
grep -q 'All requested services healthy' "$TMP/success.log"
for name in "${APP[@]}";do test -e "$STATE/$name.json";done
"$ROOT/scripts/stop_all.sh" >"$TMP/stopped.log" 2>&1
for name in "${APP[@]}";do test ! -e "$STATE/$name.json";done
echo 'PASS: seven fake processes recorded/stopped without broad matching'
echo '=== Early exit classification ==='
if PETCLINIC_FAKE_JAVA_EXIT=1 PETCLINIC_FAKE_HEALTH=fail "$ROOT/scripts/run_all.sh" --no-infra >"$TMP/early.log" 2>&1;then
 echo "ERROR: exited process reported healthy" >&2;exit 1
fi
echo 'PASS: early exit not accepted as readiness'
