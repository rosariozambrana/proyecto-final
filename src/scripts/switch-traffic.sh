#!/bin/bash
set -euo pipefail

TARGET_PORT="${1:?Uso: switch-traffic.sh <puerto> [archivo-upstream]}"
UPSTREAM_FILE="${2:-/etc/nginx/conf.d/webapi-upstream.conf}"
TEMP_FILE="${UPSTREAM_FILE}.tmp"

mkdir -p "$(dirname "$UPSTREAM_FILE")"
cat > "$TEMP_FILE" <<EOF
upstream webapi_backend {
    server 127.0.0.1:$TARGET_PORT;
}
EOF

mv "$TEMP_FILE" "$UPSTREAM_FILE"
nginx -t
nginx -s reload
echo "Nginx ahora dirige el tráfico al puerto $TARGET_PORT"
