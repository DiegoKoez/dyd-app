@echo off
setlocal enabledelayedexpansion

title DYD - Servidor

echo ========================================
echo    DYD - Iniciando Servidor
echo ========================================
echo.

REM Verificar que Node.js este instalado
node --version >nul 2>&1
if errorlevel 1 (
    echo Node.js no esta instalado en esta PC.
    pause
    exit /b 1
)

echo Node.js detectado correctamente.
echo.

REM Ir a la carpeta del servidor
cd /d "%~dp0server"

REM Instalar dependencias si no existe node_modules
if not exist "node_modules" (
    echo Instalando dependencias del servidor...
    call npm install
    if errorlevel 1 (
        echo.
        echo ERROR: No se pudieron instalar las dependencias.
        pause
        exit /b 1
    )
) else (
    echo Dependencias ya instaladas.
    echo.
)

REM Verificar si el puerto 3000 ya está en uso y cerrar automáticamente
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
    echo Cerrando proceso que usa el puerto 3000 (PID: %%p)...
    taskkill /F /PID %%p >nul 2>&1
    timeout /t 1 /nobreak >nul
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

REM Intentar una vez más
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
    set "PID_VERIFICADA=%%p"
)

if defined PID_VERIFICADA (
    echo ERROR: El puerto 3000 sigue en uso.
    echo PID del proceso: !PID_VERIFICADA!
    echo.
    pause
    exit /b 1
)

REM Intentar agregar regla de firewall (requiere admin)
echo.
echo Configurando firewall...
netsh advfirewall firewall add rule name="DYD Server" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
netsh advfirewall firewall add rule name="DYD Discovery" dir=in action=allow protocol=UDP localport=3001 >nul 2>&1
echo Firewall configurado.
echo.

REM Obtener la IP local
set "ip="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "ip=%%a"
)
set "ip=%ip: =%"

if defined ip (
    echo IP y puerto para compartir:
    echo.
    echo   http://%ip%:3000
) else (
    echo IP y puerto para compartir:
    echo.
    echo   http://localhost:3000
)

echo.
echo Puerto del servidor: 3000
echo Puerto de descubrimiento: 3001
echo.
echo ========================================
echo.

REM Intentar iniciar el servidor
echo Iniciando servidor...
echo.

node index.js

echo.
echo El servidor se ha detenido.
pause
goto :eof
