#!/bin/bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1}"
EXPECTED_INSTANCE="${EXPECTED_INSTANCE:-BLUE}"

health=$(curl --fail --silent "$BASE_URL/actuator/health")
instance=$(curl --fail --silent "$BASE_URL/api/instance")

[[ "$health" == *'"status":"UP"'* ]] || { echo "Health check E2E fallido: $health" >&2; exit 1; }
[[ "$instance" == "$EXPECTED_INSTANCE" ]] || { echo "Instancia esperada $EXPECTED_INSTANCE, recibida $instance" >&2; exit 1; }
echo "E2E OK: $instance respondió detrás de Nginx"
