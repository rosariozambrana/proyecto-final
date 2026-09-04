# 🚀 BLUE-GREEN DEPLOYMENT - GUÍA RÁPIDA PARA EXPONER

## ✅ Estado Pre-Demo (TODO LISTO)

```bash
✅ JAR compilado en: target/webapi-0.0.1-SNAPSHOT.jar (22 MB)
✅ BLUE corriendo en puerto 8080
✅ Nginx corriendo en puerto 80 (proxy hacia BLUE)
✅ GREEN listo para desplegar en puerto 8081
```

---

## 🎬 Secuencia de Exposición

### PASO 1️⃣: Mostrar BLUE Activa (30 segundos)

```bash
# Conectar a terminal WSL
wsl

# Navegar al proyecto
cd /mnt/c/Users/Camilo\ Sarmiento/Music/DIPLO\ PROYECTO/Proyecto\ final\ 4/proyecto-final

# Probar BLUE está activa
curl http://127.0.0.1/api/instance
# Salida esperada: BLUE

# Health check
curl http://127.0.0.1/actuator/health
# Salida esperada: {"status":"UP",...}
```

**Qué explicar:**
- BLUE es la versión actual, escuchando en puerto 8080
- Nginx en puerto 80 redirige todo a BLUE
- El endpoint `/api/instance` identifica qué instancia atiende

---

### PASO 2️⃣: Desplegar GREEN (45 segundos)

```bash
# Ejecutar deployment
src/scripts/deploy.sh

# Salida esperada:
# Desplegando GREEN en el puerto 8081
# [Espera health check...]
# BLUE-GREEN completado: tráfico dirigido a GREEN
```

**Qué explicar:**
- El script inicia GREEN en puerto 8081
- Espera hasta 60 segundos a que responda /actuator/health
- Si falla, mantiene BLUE activa (cero downtime)
- Si es exitoso, Nginx cambia el tráfico

---

### PASO 3️⃣: Verificar GREEN Activa (15 segundos)

```bash
# Comprobar que GREEN ahora recibe tráfico
curl http://127.0.0.1/api/instance
# Salida esperada: GREEN

# Health check
curl http://127.0.0.1/actuator/health
# Salida esperada: {"status":"UP",...}
```

**Qué explicar:**
- A través de Nginx (puerto 80), ahora responde GREEN
- El cambio fue instantáneo (< 100ms)
- BLUE sigue corriendo en puerto 8080 (inactiva)

---

### PASO 4️⃣: E2E Test (10 segundos)

```bash
# Ejecutar validación end-to-end
EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh

# Salida esperada:
# E2E OK: GREEN respondió detrás de Nginx
```

**Qué explicar:**
- Valida que /actuator/health responde UP
- Verifica que /api/instance es GREEN
- Confirma que Nginx está redirigiendo correctamente

---

### PASO 5️⃣: Ver Logs (Opcional - 15 segundos)

```bash
# Mostrar logs de GREEN
tail -f app-8081.log
# Presionar Ctrl+C para salir
```

**Qué explicar:**
- Los logs muestran que GREEN se inició correctamente
- Spring Boot escucha en puerto 8081
- Todas las solicitudes se procesan sin errores

---

### PASO 6️⃣: Rollback (Opcional - 30 segundos)

```bash
# Simular que GREEN tiene un error
src/scripts/rollback.sh

# Salida esperada:
# Rollback completado: tráfico dirigido a BLUE

# Verificar que volvió a BLUE
curl http://127.0.0.1/api/instance
# Salida esperada: BLUE
```

**Qué explicar:**
- Rollback revierte a BLUE en segundos
- GREEN sigue corriendo (puedes investigar logs sin prisa)
- Usuarios nunca sienten la interrupción

---

## 📊 Flujo Visual Completo

```
ESTADO 1: BLUE Activa
  Nginx:80 → BLUE:8080
  curl /api/instance → BLUE

ESTADO 2: Despliegue de GREEN
  GREEN:8081 arranca (health check...)
  Si OK → ESTADO 3
  Si FAIL → Permanece en ESTADO 1

ESTADO 3: GREEN Activa
  Nginx:80 → GREEN:8081
  curl /api/instance → GREEN
  BLUE:8080 sigue corriendo (pero sin tráfico)

ESTADO 4: Rollback (si es necesario)
  Nginx:80 → BLUE:8080
  curl /api/instance → BLUE
  GREEN:8081 sigue corriendo (para investigar)
```

---

## 🎯 Puntos Clave a Resaltar

✅ **Cero Downtime**
- El cambio toma < 100ms
- BLUE no se detiene hasta que GREEN está listo
- Usuarios nunca ven interrupciones

✅ **Validación Automática**
- Health check previene versiones rotas
- Si GREEN no responde en 60s → Falla y mantiene BLUE

✅ **Rollback Instantáneo**
- Vuelve a BLUE en segundos
- GREEN sigue corriendo (debugging post-incident)

✅ **Automatización Total**
- Scripts bash hacen todo
- Cero intervención manual
- Deployments seguros en producción

---

## ⏱️ Timing Total

- Explicación inicial: 2 minutos
- Demostración paso a paso: 15-20 minutos
- Preguntas: 5 minutos
- **TOTAL: ~25 minutos**

---

## 🚀 Atajos Útiles

```bash
# Ver estado actual
cat .active_color

# Ver procesos Java corriendo
ps aux | grep java

# Ver puertos escuchando
netstat -tlnp 2>/dev/null | grep -E ':(80|8080|8081)'

# Ver Nginx upstream actual
sudo cat /etc/nginx/conf.d/webapi.conf

# Limpiar logs antiguos
rm -f app-8080.log app-8081.log

# Reiniciar Nginx (si hay problemas)
sudo service nginx restart
```

---

## ✨ Conclusión

**Blue-Green Deployment te permite:**
- Desplegar con confianza
- Sin downtime ni riesgo
- Con rollback automático
- En producción 24/7

🎉 **¡Listo para exponer!**
