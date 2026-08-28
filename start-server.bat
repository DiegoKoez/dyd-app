@echo off
setlocal enabledelayedexpansion

title DYD - Servidor de Juego

echo ========================================
echo    DYD - Iniciando Servidor...
echo ========================================
echo.

REM Verificar que Node.js este instalado
echo Verificando Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Node.js no esta instalado en esta PC.
    echo.
    echo Por favor descarga e instala Node.js desde:
    echo https://nodejs.org/
    echo.
    pause
    goto :eof
)

echo Node.js detectado correctamente.
echo.

REM Verificar que estamos en la carpeta del servidor
if not exist "node_modules" (
    echo Dependencias del servidor no encontradas.
    echo Instalando dependencias...
    echo.
    call npm.cmd install
    if errorlevel 1 (
        echo.
        echo ERROR: No se pudieron instalar las dependencias.
        echo Verifica tu conexion a internet.
        pause
        exit /b 1
    )
    echo Dependencias instaladas exitosamente.
    echo.
) else (
    echo Dependencias ya instaladas.
    echo.
)

echo ========================================
echo    Iniciando Servidor...
echo ========================================
echo.

REM Obtener la IP local correctamente
set "ip="
for /f "tokens=3 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "ip=%%a"
)

REM Limpiar la IP (quitar espacios)
set "ip=!ip: =!"
set "ip=!ip:~1!"

REM Intentar obtener la primera IP de la red (no localhost)
set "network_ip="
for /f "tokens=3 delims=:" %%a in ('ipconfig ^| findstr /i "Wired"') do (
    set "network_ip=%%a"
)
set "network_ip=!network_ip: =!"
set "network_ip=!network_ip:~1!"

for /f "tokens=3 delims=:" %%a in ('ipconfig ^| findstr /i "Wireless"') do (
    if "!network_ip!"=="" set "network_ip=%%a"
)
set "network_ip=!network_ip: =!"
set "network_ip=!network_ip:~1!"

REM Si no hay IP de red, usar localhost
if "!network_ip!"=="" (
    set "network_ip=127.0.0.1"
)

REM Verificar si node_modules existe en la carpeta actual
if not exist "node_modules" (
    echo Las dependencias del servidor no se encontraron.
    echo Intenta ejecutar este script desde la carpeta 'server'.
    pause
    goto :eof
)

echo ========================================
echo    Servidor iniciado correctamente!
echo ========================================
echo.
echo IP del servidor: !network_ip!:3000
echo.
echo Puerto del servidor: 3000
echo Puerto de descubrimiento: 3001
echo.
echo ========================================
echo.
echo IMPORTANTE:
echo 1. Asegurate que los celulares estén en la misma red WiFi
echo 2. Permite el puerto 3000 en el firewall de Windows
echo 3. Usa la IP mostrada arriba en la app del celular
echo.
echo Presiona Ctrl+C para detener el servidor.
echo ========================================
echo.

REM Intentar agregar regla de firewall (requiere admin)
echo Configurando firewall...
netsh advfirewall firewall add rule name="DYD Server" dir=in action=allow protocol=TCP localport=3000 2>nul
netsh advfirewall firewall add rule name="DYD Discovery" dir=in action=allow protocol=UDP localport=3001 2>nul
if errorlevel 1 (
    echo Advertencia: No se pudo configurar el firewall (requiere permisos de administrador)
    echo Si los celulares no pueden conectar, permite manualmente el puerto 3000 en el firewall.
    echo.
)

echo.
echo ========================================
echo    Inicializando Servidor Socket.IO...
echo ========================================
echo.

REM Iniciar el servidor
node index.js

echo.
echo El servidor se ha detenido.
echo.

REM Detener reglas de firewall
netsh advfirewall firewall delete rule name="DYD Server" 2>nul
netsh advfirewall firewall delete rule name="DYD Discovery" 2>nul

pause
goto :eof
