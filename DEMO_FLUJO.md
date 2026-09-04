---
marp: true
theme: default
style: |
  section {
    font-family: 'Courier New', monospace;
    background: #f5f5f5;
  }
  h1 {
    color: #d32f2f;
    background: linear-gradient(135deg, #1976d2 0%, #0d47a1 100%);
    color: white;
    padding: 20px;
    border-radius: 10px;
  }
  h2 {
    color: #1976d2;
    border-left: 5px solid #1976d2;
    padding-left: 10px;
  }
  code {
    background: #263238;
    color: #aed581;
    padding: 2px 5px;
    border-radius: 3px;
  }
  pre {
    background: #263238;
    color: #aed581;
    padding: 15px;
    border-radius: 5px;
  }
  .success { color: #388e3c; font-weight: bold; }
  .error { color: #d32f2f; font-weight: bold; }
  .info { color: #1976d2; font-weight: bold; }
paginate: true
---

# 🚀 DEMO LIVE: Blue-Green Deployment
## Flujo Completo Paso a Paso

---

# Estado Inicial: BLUE está Activa

```bash
$ curl -s http://127.0.0.1/api/instance
BLUE

$ curl -s http://127.0.0.1/actuator/health | grep status
"status":"UP"
```

**📊 Diagrama actual:**
```
Nginx :80
  └─ webapi_backend → 127.0.0.1:8080 (BLUE) ✅ ACTIVA
  
GREEN :8081 → (sin tráfico)
```

---

# Paso 1: Compilar el JAR

```bash
$ ./mvnw clean package

[INFO] Scanning for projects...
[INFO] -------< com.cicd:webapi >-------
[INFO] Building webapi 0.0.1-SNAPSHOT
[INFO] --------------------------------
[INFO] --- maven-clean-plugin:3.2.0:clean (default-clean) @ webapi ---
[INFO] --- maven-compiler-plugin:3.10.1:compile (default-compile) @ webapi ---
[INFO] --- maven-jar-plugin:3.3.0:jar (default-jar) @ webapi ---
[INFO] BUILD SUCCESS [00:25]
[INFO] JAR: target/webapi-0.0.1-SNAPSHOT.jar
```

**Resultado:** ✅ JAR listo en `target/webapi-0.0.1-SNAPSHOT.jar`

---

# Paso 2: Ejecutar deploy.sh

```bash
$ src/scripts/deploy.sh

Desplegando GREEN en el puerto 8081
```

**¿Qué hace el script internamente?**

```bash
# 1. Lee quién está activo
active_color="BLUE"

# 2. Alterna a GREEN
target_color="GREEN"
target_port=8081

# 3. Inicia la instancia
nohup java -jar target/webapi-0.0.1-SNAPSHOT.jar \
    --server.port=8081 \
    --app.instance=GREEN > app-8081.log 2>&1 &

# 4. Espera health check (hasta 60s)
```

---

# Paso 2.1: Health Check en Progreso

```bash
# El script valida continuamente:

$ for i in {1..5}; do
    echo "Intento $i..."
    curl -s -o /dev/null -w '%{http_code}' \
         http://127.0.0.1:8081/actuator/health
    sleep 2
done

# Salida esperada:
Intento 1...
000  # No responde aún
Intento 2...
000  # Arrancando...
Intento 3...
200  # ✅ GREEN está UP!
```

**En paralelo: BLUE sigue sirviendo tráfico**

---

# Paso 2.2: Health Check Exitoso

```bash
$ curl -s http://127.0.0.1:8081/actuator/health | python3 -m json.tool

{
  "status": "UP",
  "components": {
    "diskSpace": { "status": "UP" },
    "livenessState": { "status": "UP" },
    "readinessState": { "status": "UP" }
  }
}
```

**Estado en este punto:**
```
BLUE :8080  ✅ ACTIVA (recibe tráfico)
GREEN :8081 ✅ SALUDABLE (lista para promover)
```

---

# Paso 3: Switch de Tráfico (Automático)

El script ejecuta `switch-traffic.sh`:

```bash
# Genera archivo dinámico
cat > /etc/nginx/conf.d/webapi-upstream.conf <<EOF
upstream webapi_backend {
    server 127.0.0.1:8081;  # ⭐ AHORA APUNTA A GREEN
}
EOF

# Valida configuración
$ nginx -t
nginx: configuration file /etc/nginx/nginx.conf test is successful

# Recarga sin downtime
$ nginx -s reload
Nginx ahora dirige el tráfico al puerto 8081
```

**Momento CRÍTICO:** El cambio toma < 100ms

---

# Paso 3.1: Nginx Apunta a GREEN

```bash
# Verificar la configuración actual de Nginx
$ sudo cat /etc/nginx/conf.d/webapi-upstream.conf

upstream webapi_backend {
    server 127.0.0.1:8081;  # ✅ VERDE (GREEN)
}
```

**Estado ahora:**
```
Nginx :80 → apunta a GREEN:8081 ✅
BLUE :8080 → SIN TRÁFICO (pero sigue corriendo)
```

---

# Paso 4: Guardar Estado

```bash
$ echo "GREEN" > .active_color

$ cat .active_color
GREEN
```

**El script imprime:**
```
BLUE-GREEN completado: tráfico dirigido a GREEN
```

---

# Paso 5: Validar con E2E Test

```bash
$ EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh
```

**¿Qué valida?**

```bash
# 1. Chequea salud
health=$(curl -s http://127.0.0.1/actuator/health)
[[ "$health" == *'"status":"UP"'* ]] ✅

# 2. Verifica QIÉN RESPONDE (a través de Nginx)
instance=$(curl -s http://127.0.0.1/api/instance)
[[ "$instance" == "GREEN" ]] ✅

# Resultado
E2E OK: GREEN respondió detrás de Nginx
```

---

# Paso 5.1: Flujo Real de Peticiones

```
Usuario hace petición:
  GET http://127.0.0.1/api/instance
         ↓
Nginx escucha en :80
         ↓
Nginx consulta upstream:
  server 127.0.0.1:8081
         ↓
GREEN responde:
  "GREEN"
         ↓
Nginx devuelve la respuesta al usuario
         ↓
E2E valida: ✅ GREEN está activa
```

---

# Comparación: ANTES vs DESPUÉS

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">

### ANTES (BLUE Activa)
```
Nginx :80
  └─ :8080 (BLUE)
     GET /api/instance
     → "BLUE"
     
GREEN :8081
  (Sin tráfico)
```

### DESPUÉS (GREEN Activa)
```
Nginx :80
  └─ :8081 (GREEN)
     GET /api/instance
     → "GREEN"
     
BLUE :8080
  (Sin tráfico)
```

</div>

---

# Vista de Logs (Prueba)

```bash
$ tail -f app-8081.log

2026-09-04 14:23:15 [main] INFO o.s.b.StartupInfoLogger:
  Starting WebapiApplication v0.0.1-SNAPSHOT
  
2026-09-04 14:23:16 [main] INFO o.s.b.w.e.tomcat.TomcatWebServer:
  Tomcat initialized with port(s): 8081 (http)
  
2026-09-04 14:23:17 [main] INFO o.s.b.w.e.tomcat.TomcatWebServer:
  Tomcat started on port(s): 8081 (https=false) with context path ''
  
2026-09-04 14:23:17 [main] INFO o.s.b.StartupInfoLogger:
  Started WebapiApplication in 2.145 seconds
  
2026-09-04 14:23:18 [http-nio-8081-exec-1] INFO com.cicd.webapi:
  GET /actuator/health → 200 OK (health check)
```

---

# Prueba de Carga (Verificación)

```bash
$ curl -i http://127.0.0.1/api/instance

HTTP/1.1 200 OK
Server: nginx/1.18.0
Date: Thu, 04 Sep 2026 14:23:18 GMT
Content-Type: text/plain;charset=UTF-8
Content-Length: 5
Connection: keep-alive
X-Real-IP: 127.0.0.1

GREEN
```

**Comprobación:** ✅ GREEN responde a través de Nginx

---

# Escenario: Error en Deployment

**Si hubiera fallado el health check:**

```bash
$ src/scripts/deploy.sh

Desplegando GREEN en el puerto 8081
Health check fallido para GREEN (8081)
ERROR: No se pudo validar la instancia

# Resultado:
- EXIT 1 (falla)
- BLUE sigue activa ✅
- GREEN nunca recibe tráfico
- Nginx sigue apuntando a :8080
```

---

# Rollback en Emergencia (Si fuera necesario)

```bash
$ src/scripts/rollback.sh

# El script:
# 1. Lee estado actual (.active_color → GREEN)
# 2. Determina versión anterior (BLUE)
# 3. Valida que BLUE está saludable
# 4. Ejecuta switch-traffic.sh 8080
# 5. Nginx vuelve a :8080

Rollback completado: tráfico dirigido a BLUE
```

**Resultado:**
```
Nginx :80 → apunta a BLUE:8080 ✅
GREEN :8081 → SIGUE CORRIENDO (para investigar)
```

---

# Verificar Rollback

```bash
$ curl -s http://127.0.0.1/api/instance
BLUE

$ cat .active_color
BLUE

$ tail app-8080.log
# Verás logs normales (BLUE está atendiendo)

$ tail app-8081.log
# Puedes investigar qué pasó en GREEN
```

---

# Flujo Visual Completo

```
┌─────────────────────────────────────────────┐
│  1. User: ./mvnw clean package              │
│     Result: ✅ JAR compilado                │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│  2. User: src/scripts/deploy.sh             │
│  2.1 Script inicia GREEN:8081               │
│  2.2 Health check (waiting...)              │
│  Result: ✅ GREEN saludable                 │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│  3. Script: switch-traffic.sh               │
│  3.1 Genera webapi-upstream.conf            │
│  3.2 nginx -t (valida)                      │
│  3.3 nginx -s reload                        │
│  Result: ✅ Nginx apunta a GREEN:8081       │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│  4. Script: guarda estado                   │
│  echo GREEN > .active_color                 │
│  Result: ✅ Estado persistido                │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│  5. User: e2e-test.sh                       │
│  5.1 curl /actuator/health                  │
│  5.2 curl /api/instance → GREEN             │
│  Result: ✅ E2E OK!                          │
└─────────────────────────────────────────────┘
```

---

# Resumen: Qué Pasó

| Etapa | Acción | Resultado |
|-------|--------|-----------|
| **Inicio** | BLUE activa | Nginx → :8080 |
| **Compilar** | mvnw clean package | JAR listo |
| **Deploy** | deploy.sh inicia GREEN | Health check ✅ |
| **Switch** | switch-traffic.sh | Nginx → :8081 |
| **Estado** | Guarda GREEN como activa | .active_color = GREEN |
| **Test** | e2e-test.sh valida | GREEN responde |

**Tiempo total:** ~35 segundos (20s compilación + 15s deploy)

---

# Comandos para Practicar

```bash
# 1. Compilar
./mvnw clean package

# 2. Desplegar
src/scripts/deploy.sh

# 3. Verificar instancia activa
curl http://127.0.0.1/api/instance

# 4. E2E Test
EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh

# 5. Ver estado
cat .active_color

# 6. Logs de GREEN
tail -f app-8081.log
```

---

# Preguntas Clave para Responder

❓ **¿Cuánto downtime hay?**
→ Cero. Nginx cambia en < 100ms

❓ **¿Qué pasa si GREEN falla?**
→ Health check falla, BLUE sigue activa, GREEN nunca recibe tráfico

❓ **¿Cómo vuelvo atrás?**
→ `./src/scripts/rollback.sh` (GREEN sigue corriendo para investigar)

❓ **¿Por qué dos puertos?**
→ Para poder tener dos versiones simultáneamente

❓ **¿Nginx es un punto único de fallo?**
→ No, es solo un router. Si cae, ambas instancias siguen corriendo

---

# Próximo Paso: Segundo Deployment

```bash
$ src/scripts/deploy.sh

# Ahora deploy.sh detecta que GREEN está activa
# Y despliega la SIGUIENTE versión en BLUE:8080
# Health check → Switch → ¡BLUE activa!

$ curl http://127.0.0.1/api/instance
BLUE
```

**Ciclo se repite:** BLUE ↔ GREEN ↔ BLUE ↔ ...

---

# 🎯 Resumen Ejecutivo

**Blue-Green Deployment permite:**
- ✅ Deployment sin downtime
- ✅ Rollback instantáneo
- ✅ Validación pre-promoción
- ✅ Debugging post-rollback
- ✅ Automatización total

**Stack usado:**
- Java 21 + Spring Boot 3.2
- Nginx (proxy reverso)
- Bash scripts (orquestación)
- Health checks (validación)

**Resultado:** Deploys confiables en producción 🚀
