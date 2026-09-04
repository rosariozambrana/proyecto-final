@echo off
REM ============================================
REM  BLUE-GREEN DEPLOYMENT - ACCESO RÁPIDO
REM ============================================
echo.
echo ╔════════════════════════════════════════════════════╗
echo ║  BLUE-GREEN DEPLOYMENT - LISTO PARA EXPONER      ║
echo ╚════════════════════════════════════════════════════╝
echo.
echo ESTADO ACTUAL:
echo   ✅ BLUE:8080 - Activa
echo   ✅ Nginx:80 - Proxy funcionando
echo   ✅ GREEN:8081 - Listo para desplegar
echo.
echo ════════════════════════════════════════════════════
echo.
echo Para iniciar la demo:
echo.
echo 1. Abre WSL:
echo    wsl
echo.
echo 2. Navega al proyecto:
echo    cd /mnt/c/Users/Camilo\ Sarmiento/Music/DIPLO\ PROYECTO/Proyecto\ final\ 4/proyecto-final
echo.
echo 3. Ejecuta paso a paso:
echo    ① curl http://127.0.0.1/api/instance
echo    ② src/scripts/deploy.sh
echo    ③ curl http://127.0.0.1/api/instance
echo    ④ EXPECTED_INSTANCE=GREEN src/scripts/e2e-test.sh
echo.
echo ════════════════════════════════════════════════════
echo.
echo DOCUMENTACIÓN DISPONIBLE:
echo   📄 GUIA_RAPIDA_EXPOSICION.md - LEER ESTO
echo   📄 Blue-Green-Deployment.pptx - Conceptos
echo   📄 DEMO_Flujo_Completo.pptx - Demo paso a paso
echo.
echo ════════════════════════════════════════════════════
echo.
pause
