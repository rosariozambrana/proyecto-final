---
marp: true
theme: default
style: |
  section {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  }
  h1 {
    color: #0066cc;
  }
  h2 {
    color: #0066cc;
    border-bottom: 3px solid #0066cc;
    padding-bottom: 10px;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 20px;
  }
paginate: true
---

# Blue-Green Deployment
## Estrategia de despliegue sin interrupción

![bg right:40%](https://via.placeholder.com/400x300?text=CI%2FCD)

---

# Tabla de Contenidos

1. ¿Qué es Blue-Green?
2. Ventajas y desventajas
3. Arquitectura del sistema
4. Flujo de deployment
5. Componentes técnicos
6. Health checks y validación
7. Rollback automático
8. Demostración en vivo

---

# ¿Qué es Blue-Green Deployment?

Blue-Green es una **estrategia de despliegue** que:

- Mantiene **dos instancias idénticas** ejecutándose simultáneamente
- Una está **ACTIVA** (recibiendo tráfico)
- Otra está **INACTIVA** (lista para promover)
- El cambio de tráfico es **instantáneo** y **reversible**

```
Nginx (Puerto 80)
    ↓
    ├─ BLUE (8080) ← Activa
    └─ GREEN (8081) ← Espera
```

**Resultado:** Cero downtime, bajo riesgo

---

# Ventajas 🎯

| Ventaja | Descripción |
|---------|-------------|
| **Cero Downtime** | El cambio es instantáneo |
| **Rollback Rápido** | Vuelve a versión anterior en segundos |
| **Testing en Producción** | Valida antes de recibir tráfico real |
| **Debugging** | Logs disponibles de versión fallida |
| **Predictibilidad** | Ambiente idéntico al de producción |

---

# Desventajas ⚠️

- **Recursos duplicados:** Necesita 2x capacidad de instancias
- **Sincronización de datos:** Debe gestionar estado compartido
- **Complejidad:** Más scripts y configuración que otros métodos
- **DB migrations:** Deben ser reversibles

---

# Arquitectura del Sistema

```
┌─────────────────────────────────────────────┐
│         Internet (http://localhost)          │
└─────────────────────────────────────────────┘
                     ↓
         ┌───────────────────────┐
         │   Nginx (Puerto 80)   │
         │  - Proxy reverso      │
         │  - Load balancer      │
         └───────────────────────┘
             ↓              ↓
    ┌──────────────┐  ┌──────────────┐
    │ BLUE:8080    │  │ GREEN:8081   │
    │ Spring Boot  │  │ Spring Boot  │
    │ Activa       │  │ Inactiva     │
    └──────────────┘  └──────────────┘
```

**Nginx** decide a cuál instancia dirigir el tráfico

---

# Configuración de Nginx

```nginx
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://webapi_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

upstream webapi_backend {
    server 127.0.0.1:8080;  # Dinámicamente actualizado
}
```

El archivo `webapi-upstream.conf` se **genera automáticamente**

---

# Flujo de Deployment

```
┌─ Estado Inicial
│  BLUE:8080 activa
│
├─ 1. Nueva versión en GREEN:8081
│     nohup java -jar ... --app.instance=GREEN
│
├─ 2. Health check GREEN
│     curl /actuator/health
│
├─ 3. ¿Responde 200?
│  ├─ SÍ  → Paso 4
│  └─ NO  → FALLA (rollback automático)
│
├─ 4. Switch traffic
│     switch-traffic.sh → Nginx apunta a GREEN
│
└─ Estado Final
   GREEN:8081 activa
```

---

# Scripts Implementados

<div class="columns">

**deploy.sh**
- Inicia nueva versión
- Espera health check
- Ejecuta switch-traffic
- Max 60 segundos

**switch-traffic.sh**
- Genera upstream file
- Valida config de Nginx
- Recarga balanceador

</div>

<div class="columns">

**e2e-test.sh**
- Verifica salud API
- Confirma instancia activa
- Valida routing

**rollback.sh**
- Detecta fallo
- Revierte instancia
- Mantiene logs

</div>

---

# Endpoints de la API

```bash
GET /api/instance
→ Responde "BLUE" o "GREEN"

GET /actuator/health
→ {"status":"UP"} si está saludable

GET /health
→ "Server Healthy!"

GET /
→ "Hello CI/CD World!"
```

Permiten **identificar qué instancia** procesa cada solicitud

---

# Health Check: El Guardián

```bash
# Antes de promover, 60 segundos de validación
until curl -f http://127.0.0.1:PORT/actuator/health; do
    sleep 2
done

# Si falla:
echo "Health check fallido" && exit 1

# Resultado:
# ✓ Promoción segura
# ✓ Versión rota nunca recibe tráfico
```

**Crítico para evitar:** Downtime, experiencia de usuario degradada, errores en cascada

---

# Procedimiento de Rollback

<div class="columns">

**Escenario de error:**
1. Green se despliega
2. Falla después de 5 min
3. Usuarios reportan error

</div>

<div class="columns">

**Rollback en 3 pasos:**
```bash
# 1. Ejecutar
./src/scripts/rollback.sh

# 2. Validar salud de BLUE
curl /actuator/health

# 3. Nginx vuelve a BLUE
# Tráfico restaurado
```

</div>

**Ventaja:** Instancia fallida (GREEN) sigue corriendo → **puedes revisar logs sin prisa**

---

# Ejemplo: Deployment Real

```bash
# 1. Compilar
$ ./mvnw clean package
[INFO] BUILD SUCCESS

# 2. Desplegar
$ src/scripts/deploy.sh
Desplegando GREEN en el puerto 8081
✓ Health check OK
✓ Traffic switched
BLUE-GREEN completado: tráfico dirigido a GREEN

# 3. Verificar
$ EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh
E2E OK: GREEN respondió detrás de Nginx
```

---

# Monitoreo Post-Deployment

```bash
# Ver logs en tiempo real
tail -f app-8081.log

# Verificar qué instancia está activa
curl http://127.0.0.1/api/instance
GREEN

# Probar latencia
ab -n 100 -c 10 http://127.0.0.1/

# Si algo falla: rollback instantáneo
./src/scripts/rollback.sh
```

---

# Comparación: Métodos de Deployment

| Estrategia | Downtime | Rollback | Riesgo | Recursos |
|-----------|----------|----------|--------|----------|
| **Blue-Green** | ❌ Cero | ✓ 1 seg | Bajo | 2x |
| **Canary** | ❌ Cero | ✓ 1 seg | Medio | 1.1x |
| **Rolling** | ⚠️ Parcial | ✓ Lento | Medio | 1.5x |
| **Direct** | ⚠️ Total | ✗ Manual | Alto | 1x |

**Conclusión:** Blue-Green es la más segura para aplicaciones críticas

---

# Casos de Uso Ideales

✅ **Aplicaciones críticas** (banking, e-commerce, SaaS)
✅ **Deploys frecuentes** (DevOps/Continuous Delivery)
✅ **Ambiente de producción** (requiere validación)
✅ **Cambios sin pausa** (horarios de actividad)
❌ **Aplicaciones stateful** complejas
❌ **Recursos muy limitados**

---

# Stack Tecnológico

```
Java 21
├─ Spring Boot 3.2.5
│  ├─ Spring Web
│  └─ Spring Actuator (health checks)
├─ Maven
└─ Bash Scripts

Infraestructura
├─ Nginx (proxy reverso)
├─ nohup (background process)
└─ curl (health checks)
```

---

# Variables de Configuración

```bash
# Personalizable por ambiente
APP_DIR          # Directorio de la app
JAR_PATH         # Ruta del .jar
PORT_BLUE        # Puerto instancia BLUE (default: 8080)
PORT_GREEN       # Puerto instancia GREEN (default: 8081)
STATE_FILE       # Archivo de estado (.active_color)
HEALTH_TIMEOUT   # Timeout health check (default: 60s)
NGINX_UPSTREAM   # Ruta del upstream file
```

---

# Flujo Completo (Resumen)

```
1. Compilar código
   ↓
2. Ejecutar deploy.sh
   ├─ Inicia instancia inactiva
   ├─ Espera health check (60s)
   └─ Si falla → EXIT
   ↓
3. Switch-traffic.sh
   ├─ Genera nuevo upstream.conf
   ├─ Valida con nginx -t
   └─ Recarga nginx -s reload
   ↓
4. Verificar con e2e-test.sh
   ├─ Chequea /actuator/health
   └─ Confirma instancia correcta
   ↓
5. Monitorear en producción
   └─ Si error → rollback.sh
```

---

# Lecciones Aprendidas

1. **Health check es crítico:** No promocionar sin validación
2. **Timeout necesario:** Evita esperas infinitas
3. **Logging es salvavidas:** Guarda logs de versión fallida
4. **Automatización total:** Scripts bash confiables
5. **Testing previo:** E2E debe ser inmediato post-deploy

---

# Conclusiones

## Blue-Green es:

✓ **Seguro** → Health check previene versiones rotas  
✓ **Rápido** → Cambio instantáneo sin downtime  
✓ **Reversible** → Rollback en segundos  
✓ **Automatizable** → Deploys sin intervención manual  
✓ **Observable** → Identifica qué instancia procesa cada solicitud  

**Resultado:** Deploys confiables en producción 🚀

---

# Demo: ¿Preguntas?

```bash
# Para replicar en tu máquina:
$ git clone <repo>
$ cd proyecto-final
$ ./mvnw clean package
$ src/scripts/deploy.sh
$ EXPECTED_INSTANCE=BLUE src/scripts/e2e-test.sh
```

**Repositorio:** [proyecto-final](.)  
**Documentación:** [README.md](README.md)
