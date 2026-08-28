@echo off
chcp 65001 >nul
title DYD Server (Sin Admin)
echo ========================================
echo    DYD Server - Modo Sin Admin
echo ========================================
echo.
echo NOTA: Si no conecta, ejecuta la version
echo       INICIAR_SERVIDOR_ADMIN.bat
echo.
echo ========================================
echo    INICIANDO SERVIDOR...
echo ========================================
echo.
node index.js

pause
