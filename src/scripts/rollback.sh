#!/bin/bash
set -euo pipefail

APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE_FILE="${STATE_FILE:-$APP_DIR/.active_color}"
PORT_BLUE="${PORT_BLUE:-8080}"
PORT_GREEN="${PORT_GREEN:-8081}"
NGINX_UPSTREAM_FILE="${NGINX_UPSTREAM_FILE:-/etc/nginx/conf.d/webapi-upstream.conf}"

[[ -f "$STATE_FILE" ]] || { echo "No existe estado activo para hacer rollback" >&2; exit 1; }
active_color=$(<"$STATE_FILE")
if [[ "$active_color" == "BLUE" ]]; then
    rollback_color="GREEN"
    rollback_port="$PORT_GREEN"
else
    rollback_color="BLUE"
    rollback_port="$PORT_BLUE"
fi

if [[ $(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$rollback_port/actuator/health" || true) != "200" ]]; then
    echo "La instancia $rollback_color no está saludable; rollback cancelado" >&2
    exit 1
fi

"$(dirname "$0")/switch-traffic.sh" "$rollback_port" "$NGINX_UPSTREAM_FILE"
printf '%s\n' "$rollback_color" > "$STATE_FILE"
echo "Rollback completado: tráfico dirigido a $rollback_color"
