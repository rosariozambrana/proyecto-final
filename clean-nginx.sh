#!/bin/bash

echo "🧹 Limpiando configuración antigua..."

# Detener Nginx
sudo service nginx stop

# Limpiar conf.d completamente
sudo rm -f /etc/nginx/conf.d/*.conf

# Crear configuración nueva (completa en un archivo)
sudo tee /etc/nginx/conf.d/webapi.conf > /dev/null <<'EOF'
upstream webapi_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80 default_server;
    server_name _;
    
    location / {
        proxy_pass http://webapi_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

echo "Validando nueva configuración..."
sudo nginx -t

echo "Iniciando Nginx..."
sudo service nginx start
sleep 2

echo ""
echo "✅ Nginx limpio y corriendo"
echo ""
echo "Pruebas finales:"
echo ""

echo "Test 1 - Conexión a BLUE directo (8080):"
curl -s http://127.0.0.1:8080/api/instance
echo ""

echo "Test 2 - Conexión a través de Nginx (80):"
curl -s http://127.0.0.1/api/instance
echo ""

echo "Test 3 - Health Check via Nginx:"
curl -s http://127.0.0.1/actuator/health | head -1
echo ""

if curl -s http://127.0.0.1/api/instance | grep -q BLUE; then
    echo "✅ TODO FUNCIONANDO CORRECTAMENTE"
else
    echo "⚠️  Problema aún presente"
fi
