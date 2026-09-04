#!/bin/bash

echo "🧹 Desactivando configuración de sitios por defecto..."

sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default

echo "Limpiando conf.d..."
sudo rm -f /etc/nginx/conf.d/*.conf

echo "Creando configuración nueva..."
sudo tee /etc/nginx/conf.d/webapi.conf > /dev/null <<'EOF'
upstream webapi_backend {
    server 127.0.0.1:8080;
}

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

echo "Validando..."
sudo nginx -t

echo "Reiniciando Nginx..."
sudo systemctl restart nginx

sleep 2
echo ""
echo "✅ Nginx reconstruido"
echo ""

echo "Pruebas:"
echo ""
echo "1. BLUE directo (8080):"
curl -s http://127.0.0.1:8080/api/instance
echo ""

echo "2. A través de Nginx (80):"
curl -s http://127.0.0.1/api/instance
echo ""

echo "3. Health:"
curl -s http://127.0.0.1/actuator/health | head -1
echo ""

if curl -s http://127.0.0.1/api/instance 2>/dev/null | grep -q BLUE; then
    echo "✅✅✅ NGINX FUNCIONANDO PERFECTO"
else
    echo "❌ Aún hay problemas"
fi
