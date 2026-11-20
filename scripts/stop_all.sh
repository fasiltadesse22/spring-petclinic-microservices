#!/usr/bin/env bash
# Stop only exact recorded process instances and this script's Compose infrastructure.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE="$ROOT/target/local-supervisor"
OWNER="$ROOT/scripts/managed_process.py"
GRACE="${PETCLINIC_STOP_GRACE:-8}"
rc=0
for name in admin-server api-gateway genai-service vets-service visits-service customers-service discovery-server config-server;do
 if [[ -e "$STATE/$name.json" ]];then
  python3 "$OWNER" stop --file "$STATE/$name.json" --grace "$GRACE" || rc=1
 fi
done
if [[ -f "$STATE/infra.project" ]];then
 project="$(cat "$STATE/infra.project")"
 if [[ "$project" =~ ^[a-z][a-z0-9_-]{1,50}$ ]];then
  docker compose -p "$project" -f "$ROOT/docker-compose.yml" stop grafana-server prometheus-server tracing-server || rc=1
  docker compose -p "$project" -f "$ROOT/docker-compose.yml" rm -f grafana-server prometheus-server tracing-server || rc=1
  if ((rc==0));then rm -f "$STATE/infra.project";fi
 else
  echo "Invalid Compose ownership marker; no Docker resources touched" >&2;rc=1
 fi
fi
if ((rc!=0));then echo "Some owned resources require inspection: $STATE" >&2;exit "$rc";fi
echo "Only verified owned resources stopped; no broad process or container cleanup."
