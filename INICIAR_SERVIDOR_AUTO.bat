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

REM Verificar si el puerto 3000 ya está en uso
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
    set "PID_OLD=%%p"
    
    echo ========================================
    echo ADVERTENCIA: El puerto 3000 ya está en uso
    echo ========================================
    echo Proceso node.exe con PID: !PID_OLD!
    echo.
    echo Para cerrar, presiona C o cierra desde Task Manager
    echo ========================================
    echo.
    
    set /p RESPONDER="Presiona C para cerrar el proceso actual o cualquier otra tecla si ya lo cerraste: "
    
    if /i not "%RESPONDER%"=="C" (
        echo.
        echo Verificando si el puerto está libre...
        timeout /t 2 /nobreak >nul
        goto :after_port_check
    )
    
    echo.
    echo Para cerrar el proceso, ejecuta:
    echo ========================================
    echo taskkill /F /PID !PID_OLD!
    echo ========================================
    echo.
    echo Presiona una tecla para continuar después de cerrar...
    pause >nul
    
    REM Esperar a que el usuario cierre el proceso
    timeout /t 3 /nobreak >nul
)

:after_port_check

REM Verificar si el puerto ya no está en uso
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":3000 LISTENING"') do (
    set "PID_OLD=%%p"
    goto :skip_port_check
)

set "PID_OLD="

:skip_port_check

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
