#!/usr/bin/env bash
# Disposable single-JVM smoke; no Docker, paid GenAI, or host signals.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
TMP="$(mktemp -d)"
OWNER="$ROOT/scripts/managed_process.py"
PORT="${PETCLINIC_SMOKE_PORT:-18888}"
REF="${PETCLINIC_CONFIG_REF:-323993ce2519c6d02df63e08bf4458d123d3b611}"
[[ "$PORT" =~ ^[0-9]+$ ]] && ((PORT>=1024&&PORT<=65535)) || { echo 'Invalid port' >&2;exit 2; }
jar="$(find "$ROOT/spring-petclinic-config-server/target" -maxdepth 1 -type f -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' | head -1)"
[[ -f "$jar" ]] || { echo 'BLOCKED: Config Server jar not built' >&2;exit 3; }
cleanup(){
 if [[ -f "$TMP/owned.json" ]];then python3 "$OWNER" stop --file "$TMP/owned.json" --grace 8 || true;fi
 rm -rf "$TMP"
}
trap cleanup EXIT
echo "RUNTIME-SMOKE source=$(git rev-parse HEAD) config-ref=$REF"
java -version
SPRING_CLOUD_CONFIG_SERVER_GIT_DEFAULT_LABEL="$REF" nohup java -jar "$jar" --server.port="$PORT" > "$TMP/service.log" 2>&1 &
pid=$!
python3 "$OWNER" record --file "$TMP/owned.json" --pid "$pid" --jar "$jar"
deadline=$((SECONDS+60))
ready=0
while ((SECONDS<deadline));do
 if curl -fsS --max-time 3 "http://127.0.0.1:$PORT/actuator/health" > "$TMP/health.json";then ready=1;break;fi
 if ! python3 "$OWNER" check --file "$TMP/owned.json";then echo 'FAILED: JVM exited early' >&2;tail -n 30 "$TMP/service.log";exit 5;fi
 sleep 2
done
if ((ready!=1));then echo 'FAILED: JVM did not become healthy within 60s' >&2;tail -n 30 "$TMP/service.log";exit 6;fi
echo 'VERIFIED: actual Config Server JVM and loopback actuator health'
if curl -fsS --max-time 15 "http://127.0.0.1:$PORT/customers-service/default" > "$TMP/config.json";then
 python3 - "$TMP/config.json" "$REF" <<'PY'
import json,sys
try:
    result=json.load(open(sys.argv[1]))
    revision=result.get("version","")
except (ValueError,OSError,TypeError):
    revision=""
if revision and revision==sys.argv[2]:
    print("VERIFIED: fetched external Config Server environment has exact expected immutable revision")
else:
    print("UNVERIFIED: external Config Server returned 200, but revision does not establish exact pin; observed version="+str(revision)[:40])
PY
else
 echo 'UNVERIFIED: external configuration fetch; only Config Server health was established'
fi
