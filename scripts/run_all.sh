#!/usr/bin/env bash
# Owned local launcher: no broad process matching or Docker project teardown.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STATE="$ROOT/target/local-supervisor"
OWNER="$ROOT/scripts/managed_process.py"
PROJECT="${PETCLINIC_COMPOSE_PROJECT:-petclinic-learning-$(id -u)}"
TIMEOUT="${PETCLINIC_READINESS_TIMEOUT:-120}"
GRACE="${PETCLINIC_STOP_GRACE:-8}"
CONFIG_REF="${PETCLINIC_CONFIG_REF:-323993ce2519c6d02df63e08bf4458d123d3b611}"
WITH_INFRA=1
WITH_GENAI=0
CHAOS=0
INFRA=(grafana-server prometheus-server tracing-server)
APP=(config-server discovery-server customers-service visits-service vets-service api-gateway admin-server)
declare -A PORT=([config-server]=8888 [discovery-server]=8761 [customers-service]=8081 [visits-service]=8082 [vets-service]=8083 [genai-service]=8084 [api-gateway]=8080 [admin-server]=9090)
declare -A JARS=()
LAUNCHED=()
INFRA_STARTED=0
usage(){ echo "Usage: $0 [--no-infra] [--with-genai] [--chaos-monkey]"; }
for arg in "$@";do
 case "$arg" in
  --no-infra) WITH_INFRA=0;;
  --with-genai) WITH_GENAI=1;;
  --chaos-monkey) CHAOS=1;;
  --help|-h) usage;exit 0;;
  *) echo "Unknown option $arg" >&2;exit 2;;
 esac
done
((WITH_GENAI==0)) || APP+=(genai-service)
[[ "$TIMEOUT" =~ ^[0-9]+$ ]] && ((TIMEOUT>=1&&TIMEOUT<=600)) || { echo "Invalid readiness timeout" >&2;exit 2; }
[[ "$PROJECT" =~ ^[a-z][a-z0-9_-]{1,50}$ ]] || { echo "Invalid Compose project name" >&2;exit 2; }
command -v python3 >/dev/null
python3 -c 'import os,signal,sys;sys.exit(0 if hasattr(os,"pidfd_open") and hasattr(signal,"pidfd_send_signal") else 2)' || { echo "pidfd unavailable; refuse unsafe numeric PID fallback" >&2;exit 2; }
mkdir -p "$STATE"
find_jar(){
 local name="$1" matches
 matches="$(find "$ROOT/spring-petclinic-$name/target" -maxdepth 1 -type f -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' ! -name '*.original' -print 2>/dev/null | sort)"
 [[ "$(printf '%s\n' "$matches" | grep -c . || true)" == 1 ]] || { echo "Expected exactly one executable JAR for $name, found: $matches" >&2;return 1; }
 printf '%s\n' "$matches"
}
for name in "${APP[@]}";do
 JARS[$name]="$(find_jar "$name")" || { echo "Build the Maven reactor first" >&2;exit 1; }
 [[ ! -e "$STATE/$name.json" ]] || { echo "Existing ownership marker for $name; manually inspect before retry" >&2;exit 1; }
done
compose(){ docker compose -p "$PROJECT" -f "$ROOT/docker-compose.yml" "$@"; }
on_exit(){
 local result="$1" name
 trap - EXIT INT TERM
 if ((result!=0));then
  echo "Startup failed (code $result); cleaning only resources launched by this invocation" >&2
  for name in "${LAUNCHED[@]}";do python3 "$OWNER" stop --file "$STATE/$name.json" --grace "$GRACE" || true;done
  if ((INFRA_STARTED));then
   compose stop "${INFRA[@]}" || true
   compose rm -f "${INFRA[@]}" || true
   rm -f "$STATE/infra.project"
  fi
 fi
}
trap 'on_exit $?' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
start_app(){
 local name="$1" pid
 local -a profile=()
 ((CHAOS==0)) || profile+=(--spring.profiles.active=chaos-monkey)
 if [[ "$name" == config-server ]];then
  SPRING_CLOUD_CONFIG_SERVER_GIT_DEFAULT_LABEL="$CONFIG_REF" nohup java -jar "${JARS[$name]}" "--server.port=${PORT[$name]}" "${profile[@]}" > "$STATE/$name.log" 2>&1 &
 else
  nohup java -jar "${JARS[$name]}" "--server.port=${PORT[$name]}" "${profile[@]}" > "$STATE/$name.log" 2>&1 &
 fi
 pid=$!
 python3 "$OWNER" record --file "$STATE/$name.json" --pid "$pid" --jar "${JARS[$name]}"
 LAUNCHED+=("$name")
 echo "Started $name at owned PID $pid"
}
wait_ready(){
 local name="$1" deadline=$((SECONDS+TIMEOUT))
 local endpoint="http://127.0.0.1:${PORT[$name]}/actuator/health"
 while :;do
  if curl -fsS --connect-timeout 1 --max-time 3 -o /dev/null "$endpoint";then echo "Healthy: $name";return 0;fi
  if ! python3 "$OWNER" check --file "$STATE/$name.json";then
   echo "FAILED: $name process exited before health ($STATE/$name.log)" >&2
   tail -n 20 "$STATE/$name.log" >&2 || true
   return 1
  fi
  if ((SECONDS>=deadline));then
   echo "FAILED: $name not healthy within ${TIMEOUT}s" >&2
   tail -n 20 "$STATE/$name.log" >&2 || true
   return 1
  fi
  sleep 2
 done
}
if ((WITH_INFRA));then
 command -v docker >/dev/null || { echo "Docker required or select --no-infra" >&2;exit 1; }
 for name in "${INFRA[@]}";do
  # Inherited Compose defines fixed container_name; never replace another project.
  if docker container inspect "$name" >/dev/null 2>&1;then echo "Refusing existing container $name" >&2;exit 1;fi
 done
 if [[ -e "$STATE/infra.project" ]] || [[ -n "$(compose ps -q "${INFRA[@]}")" ]];then
  echo "Existing Compose project state; refusing takeover" >&2;exit 1
 fi
 printf '%s\n' "$PROJECT" > "$STATE/infra.project"
 INFRA_STARTED=1
 compose up -d "${INFRA[@]}"
fi
for name in "${APP[@]}";do
 start_app "$name"
 if [[ "$name" == config-server || "$name" == discovery-server ]];then wait_ready "$name";fi
done
for name in "${APP[@]}";do
 if [[ "$name" != config-server && "$name" != discovery-server ]];then wait_ready "$name";fi
done
echo "All requested services healthy; ownership records in $STATE"
