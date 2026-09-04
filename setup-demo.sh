#!/bin/bash
set -euo pipefail

PROJECT_DIR="/mnt/c/Users/Camilo Sarmiento/Music/DIPLO PROYECTO/Proyecto final 4/proyecto-final"
cd "$PROJECT_DIR"

echo "=========================================="
echo "  🚀 BLUE-GREEN DEPLOYMENT - SETUP DEMO"
echo "=========================================="
echo ""

# PASO 1: Configurar Nginx
echo "📋 [1/4] Configurando Nginx..."
sudo mkdir -p /etc/nginx/conf.d

sudo tee /etc/nginx/conf.d/webapi.conf > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://webapi_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

sudo tee /etc/nginx/conf.d/webapi-upstream.conf > /dev/null <<'EOF'
upstream webapi_backend {
    server 127.0.0.1:8080;
}
EOF

sudo nginx -t > /dev/null 2>&1
sudo service nginx restart > /dev/null 2>&1
sleep 2
echo "✅ Nginx configurado y corriendo en puerto 80"
echo ""

# PASO 2: Iniciar instancia BLUE en puerto 8080
echo "🔵 [2/4] Iniciando BLUE en puerto 8080..."
nohup java -jar target/webapi-0.0.1-SNAPSHOT.jar \
    --server.port=8080 \
    --app.instance=BLUE \
    > app-8080.log 2>&1 &

echo "Esperando health check..."
for i in {1..30}; do
    if curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/actuator/health | grep -q 200; then
        echo "✅ BLUE está saludable"
        break
    fi
    sleep 1
done

echo ""
echo "📊 Estado actual:"
echo "  BLUE:8080  → Activa (recibiendo tráfico)"
echo "  GREEN:8081 → No iniciada"
echo ""

# Guardar estado
echo "BLUE" > .active_color

# PASO 3: Mensaje de instrucciones
echo "=========================================="
echo "  ✅ SETUP COMPLETADO - LISTO PARA EXPONER"
echo "=========================================="
echo ""
echo "📝 Comandos disponibles para ejecutar en la exposición:"
echo ""
echo "1️⃣  VER INSTANCIA ACTIVA:"
echo "    curl http://127.0.0.1/api/instance"
echo ""
echo "2️⃣  HEALTH CHECK:"
echo "    curl http://127.0.0.1/actuator/health | python3 -m json.tool"
echo ""
echo "3️⃣  DESPLEGAR GREEN (en WSL):"
echo "    src/scripts/deploy.sh"
echo ""
echo "4️⃣  E2E TEST (en WSL):"
echo "    EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh"
echo ""
echo "5️⃣  VER LOGS DE GREEN (en WSL):"
echo "    tail -f app-8081.log"
echo ""
echo "6️⃣  ROLLBACK (en WSL):"
echo "    src/scripts/rollback.sh"
echo ""
echo "=========================================="
echo ""
echo "✨ Todo listo para la presentación!"
