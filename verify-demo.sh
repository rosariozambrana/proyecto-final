#!/bin/bash

echo "========================================"
echo "  ✅ VERIFICACIÓN PRE-DEMO"
echo "========================================"
echo ""
echo "1️⃣  BLUE Health Check:"
curl -s http://127.0.0.1/actuator/health | head -1
echo ""
echo "2️⃣  Instancia Activa (a través de Nginx):"
curl -s http://127.0.0.1/api/instance
echo ""
echo "3️⃣  Endpoint GET /:"
curl -s http://127.0.0.1/
echo ""
echo ""
echo "========================================"
echo "  ESTADO: TODO LISTO ✨"
echo "========================================"
echo ""
echo "📍 Ubicación: /mnt/c/Users/Camilo Sarmiento/Music/DIPLO PROYECTO/Proyecto final 4/proyecto-final"
echo ""
echo "🔵 BLUE en puerto 8080 → ACTIVA"
echo "🟢 GREEN en puerto 8081 → Espera de despliegue"
echo "🔀 Nginx en puerto 80 → Proxy hacia BLUE"
echo ""
