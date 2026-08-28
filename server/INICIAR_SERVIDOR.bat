@echo off
chcp 65001 >nul
title DYD Server - Inicio Automatico
color 0A

echo ========================================
echo    DYD Server - Inicio Automatico
echo ========================================
echo.

:: Cambiar a la carpeta del script
cd /d "%~dp0"

:: ========================================
:: 1. AGREGAR REGLA DE FIREWALL (requiere admin)
:: ========================================
echo [1/3] Configurando firewall...
netsh advfirewall firewall add rule name="DYD Server TCP 8080" dir=in action=allow protocol=tcp localport=8080 >nul 2>&1
netsh advfirewall firewall add rule name="DYD Server UDP 8080" dir=in action=allow protocol=udp localport=8080 >nul 2>&1
echo Firewall configurado.
echo.

:: ========================================
:: 2. OBTENER IP LOCAL
:: ========================================
echo [2/3] Obteniendo IP local...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4" ^| findstr /i "192.168"') do set LOCAL_IP=%%a
set LOCAL_IP=%LOCAL_IP: =%
if "%LOCAL_IP%"=="" set LOCAL_IP=192.168.1.82
echo IP Local: %LOCAL_IP%
echo.

:: ========================================
:: 3. INICIAR SERVIDOR
:: ========================================
echo [3/3] Iniciando servidor...
echo.
echo ========================================
echo    SERVIDOR INICIADO
echo ========================================
echo.
echo Para conectarse desde el celular/otra PC:
echo   http://%LOCAL_IP%:8080
echo.
echo Presiona Ctrl+C para detener el servidor.
echo ========================================
echo.

:: Iniciar el servidor
node index.js

pause
