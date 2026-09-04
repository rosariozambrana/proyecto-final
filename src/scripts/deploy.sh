#!/bin/bash
set -euo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
JAR_PATH="${JAR_PATH:-$APP_DIR/target/webapi-0.0.1-SNAPSHOT.jar}"
PORT_BLUE="${PORT_BLUE:-8080}"
PORT_GREEN="${PORT_GREEN:-8081}"
STATE_FILE="${STATE_FILE:-$APP_DIR/.active_color}"
NGINX_UPSTREAM_FILE="${NGINX_UPSTREAM_FILE:-/etc/nginx/conf.d/webapi-upstream.conf}"
HEALTH_TIMEOUT="${HEALTH_TIMEOUT:-60}"

[[ -f "$JAR_PATH" ]] || { echo "No se encuentra el JAR: $JAR_PATH" >&2; exit 1; }

active_color=""
[[ -f "$STATE_FILE" ]] && active_color=$(<"$STATE_FILE")
if [[ "$active_color" == "BLUE" ]]; then
    target_color="GREEN"
    target_port="$PORT_GREEN"
else
    target_color="BLUE"
    target_port="$PORT_BLUE"
fi

echo "Desplegando $target_color en el puerto $target_port"
nohup java -jar "$JAR_PATH" \
    --server.port="$target_port" \
    --app.instance="$target_color" \
    > "$APP_DIR/app-$target_port.log" 2>&1 &

deadline=$((SECONDS + HEALTH_TIMEOUT))
until [[ $(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$target_port/actuator/health" || true) == "200" ]]; do
    if (( SECONDS >= deadline )); then
        echo "Health check fallido para $target_color ($target_port)" >&2
        exit 1
    fi
    sleep 2
done

"$(dirname "$0")/switch-traffic.sh" "$target_port" "$NGINX_UPSTREAM_FILE"
printf '%s\n' "$target_color" > "$STATE_FILE"
echo "BLUE-GREEN completado: tráfico dirigido a $target_color"