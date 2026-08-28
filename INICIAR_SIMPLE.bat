@echo off
setlocal enabledelayedexpansion
title DYD Server
cd /d "%~dp0server"

echo ========================================
echo DYD Server - Iniciando automaticamente
echo ========================================
echo.

echo Verificando puerto 3000...
netstat -ano | findstr ":3000 LISTENING" >nul
if %errorlevel% equ 0 (
    echo Puerto ocupado. Cerrando proceso automaticamente...
    
    REM Obtener solo el PID del primer proceso que usa el puerto 3000
    for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
        set "PID_OLD=%%p"
    )
    
    echo Cerrando proceso PID: !PID_OLD!...
    taskkill /F /PID !PID_OLD! 2>nul
    
    timeout /t 2 /nobreak >nul
)

REM Verificación final - si el puerto sigue en uso, intentar cerrar de nuevo
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
    set "PID_VERIFICADA=%%p"
)

if defined PID_VERIFICADA (
    echo ADVERTENCIA: El puerto 3000 sigue en uso, intentando cerrar de nuevo...
    taskkill /F /PID !PID_VERIFICADA! >nul 2>&1
    timeout /t 1 /nobreak >nul
)

echo.
echo Firewall configurada...
netsh advfirewall firewall add rule name="DYD Server" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
netsh advfirewall firewall add rule name="DYD Discovery" dir=in action=allow protocol=UDP localport=3001 >nul 2>&1
echo.

echo ========================================
echo INICIANDO SERVIDOR...
echo ========================================
echo.

node index.js

echo.
echo El servidor se ha detenido.
pause
goto :eof
