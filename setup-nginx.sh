#!/bin/bash
set -euo pipefail

echo "📋 Configurando Nginx..."

# Crear directorio
sudo mkdir -p /etc/nginx/conf.d

# Crear configuración del servidor
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

# Crear upstream inicial (BLUE en 8080)
sudo tee /etc/nginx/conf.d/webapi-upstream.conf > /dev/null <<'EOF'
upstream webapi_backend {
    server 127.0.0.1:8080;
}
EOF

# Validar configuración
echo "✓ Validando Nginx..."
sudo nginx -t

# Iniciar o reiniciar Nginx
echo "✓ Iniciando Nginx..."
sudo service nginx restart

# Esperar un momento
sleep 2

# Verificar
if sudo service nginx status | grep -q active; then
    echo "✅ Nginx está corriendo en puerto 80"
else
    echo "❌ Nginx no está corriendo"
    exit 1
fi
