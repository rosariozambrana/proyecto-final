#!/bin/bash

# Detener la ejecución inmediatamente si ocurre algún error
set -e

# Configuración general
APP_NAME="webapi"
JAR_PATH="target/webapi-0.0.1-SNAPSHOT.jar"
PORT_BLUE=8080
PORT_GREEN=8081

echo "=== INICIANDO DESPLIEGUE BLUE-GREEN ==="

# 1. Validar que el archivo JAR exista antes de hacer nada
if [ ! -f "$JAR_PATH" ]; then
    echo "Error: No se encuentra el archivo JAR en $JAR_PATH. Ejecuta primero la compilación."
    exit 1
fi

# 2. Detectar qué puerto está actualmente activo en el sistema
ACTIVE_PORT=$(sudo lsof -i -P -n | grep LISTEN | grep java | awk '{print $9}' | grep -oE '[0-9]+$' | head -n 1)

if [ -z "$ACTIVE_PORT" ]; then
    echo "No hay ninguna instancia corriendo. Desplegando en Blue ($PORT_BLUE)..."
    TARGET_PORT=$PORT_BLUE
elif [ "$ACTIVE_PORT" -eq "$PORT_BLUE" ]; then
    echo "Entorno actual en Blue ($PORT_BLUE). Desplegando nueva versión en Green ($PORT_GREEN)..."
    TARGET_PORT=$PORT_GREEN
else
    echo "Entorno actual en Green ($PORT_GREEN). Desplegando nueva versión en Blue ($PORT_BLUE)..."
    TARGET_PORT=$PORT_BLUE
fi

echo "-> Puerto objetivo para el despliegue: $TARGET_PORT"

# 3. Liberar el puerto objetivo por si quedó algún proceso huérfano
echo "Liberando el puerto $TARGET_PORT si estuviera ocupado..."
sudo fuser -k ${TARGET_PORT}/tcp || true

# 4. Levantar la nueva versión en segundo plano apuntando al puerto objetivo
echo "Iniciando la aplicación en el puerto $TARGET_PORT..."
nohup java -jar -Dserver.port=$TARGET_PORT $JAR_PATH > app-$TARGET_PORT.log 2>&1 &

# 5. Esperar unos segundos para que Spring Boot inicie por completo
echo "Esperando inicio de la aplicación..."
sleep 12

# 6. Verificación de salud (Health Check) local
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$TARGET_PORT/actuator/health || echo "000")

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 404 ]; then
    echo "¡Despliegue exitoso en el puerto $TARGET_PORT!"
    echo "=== DESPLIEGUE COMPLETADO CORRECTAMENTE ==="
else
    echo "Error crítico: El servicio en el puerto $TARGET_PORT no respondió correctamente (Código HTTP: $RESPONSE)."
    echo "Revisa el archivo de log app-$TARGET_PORT.log para más detalles."
    exit 1
fi