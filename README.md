# Web API: estrategia Blue-Green

## Estrategia de deployment

La aplicación se ejecuta en dos instancias independientes: **BLUE** en el puerto `8080` y **GREEN** en el puerto `8081`. Nginx publica un único endpoint en el puerto `80` y dirige el tráfico al upstream activo.

Una nueva versión se inicia siempre en el puerto que no está activo. El tráfico sólo cambia después de que la instancia candidata responde correctamente al health check. Esto evita interrumpir la versión estable y permite volver a ella sin reinstalarla.

La instancia se identifica mediante `INSTANCE_NAME` o `--app.instance`; el valor se consulta en `GET /api/instance`.

## Health checks

- `GET /actuator/health`: health check de Spring Boot, usado antes de promover una instancia.
- `GET /health`: endpoint de compatibilidad de la API.
- `GET /api/instance`: devuelve `BLUE` o `GREEN` para comprobar qué instancia atendió la solicitud.

## Configuración de Nginx

Instalar `config/nginx/webapi.conf` en `/etc/nginx/conf.d/`. El archivo `src/scripts/switch-traffic.sh` genera `/etc/nginx/conf.d/webapi-upstream.conf`, valida la configuración con `nginx -t` y recarga Nginx sólo si la configuración es válida.

## Despliegue

Después de construir el JAR, ejecutar desde el directorio del proyecto:

```bash
./mvnw clean package
src/scripts/deploy.sh
```

Variables opcionales: `APP_DIR`, `JAR_PATH`, `PORT_BLUE`, `PORT_GREEN`, `STATE_FILE`, `NGINX_UPSTREAM_FILE` y `HEALTH_TIMEOUT`.

## Pruebas E2E

Con Nginx y una instancia activa:

```bash
EXPECTED_INSTANCE=BLUE src/scripts/e2e-test.sh
```

Para comprobar la promoción, ejecutar `src/scripts/deploy.sh` y repetir la prueba con `EXPECTED_INSTANCE=GREEN` (o el color que corresponda al estado anterior).

## Procedimiento de rollback

1. Confirmar el fallo mediante `/actuator/health` y `/api/instance`.
2. Ejecutar `src/scripts/rollback.sh`; el script comprueba la salud de la instancia anterior antes de cambiar Nginx.
3. Ejecutar de nuevo `src/scripts/e2e-test.sh` para verificar que el tráfico volvió a la versión anterior.

El rollback no detiene la instancia candidata, lo que permite investigar sus logs (`app-8080.log` o `app-8081.log`) sin afectar la recuperación del tráfico.
