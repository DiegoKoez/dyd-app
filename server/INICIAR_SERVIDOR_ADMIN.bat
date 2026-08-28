@echo off
chcp 65001 >nul
title DYD Server
echo ========================================
echo    DYD Server - Inicio Automatico
echo ========================================
echo.

:: Cambiar a la carpeta del script
cd /d "%~dp0"

:: Solicitar elevacion de privilegios
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Solicitando permisos de administrador...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
)

:: Cambiar a la carpeta del script despues de elevacion
cd /d "%~dp0"

:: Verificar si el puerto 3000 esta ocupado
echo Verificando puerto 3000...
netstat -aon | findstr :3000 >nul
if %errorlevel% EQU 0 (
    echo Puerto ocupado. Cerrando proceso...
    for /f "tokens=5" %%a in ('netstat -aon ^| findstr :3000') do (
        taskkill /PID %%a /F >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

:: Configurar firewall (requiere admin)
echo Configurando firewall...
netsh advfirewall firewall add rule name="DYD Server TCP 3000" dir=in action=allow protocol=tcp localport=3000 >nul 2>&1
netsh advfirewall firewall add rule name="DYD Server UDP 3001" dir=in action=allow protocol=udp localport=3001 >nul 2>&1
netsh advfirewall firewall add rule name="DYD Server Node" dir=in action=allow program="C:\Program Files\nodejs\node.exe" enable=yes >nul 2>&1

echo Firewall configurado correctamente.
echo.

:: Iniciar servidor
echo ========================================
echo    INICIANDO SERVIDOR...
echo ========================================
echo.
node index.js

pause
