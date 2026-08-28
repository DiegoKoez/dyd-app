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
:: 1. VERIFICAR E INSTALAR NODE.JS
:: ========================================
echo [1/5] Verificando Node.js...
where node >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Node.js no encontrado. Descargando...
    powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi' -OutFile '%temp%\node.msi'"
    echo Instalando Node.js...
    msiexec /i "%temp%\node.msi" /qn
    echo Node.js instalado.
) else (
    echo Node.js ya esta instalado.
    node --version
)
echo.

:: ========================================
:: 2. INSTALAR DEPENDENCIAS
:: ========================================
echo [2/5] Instalando dependencias...
if not exist "node_modules" (
    call npm install
    echo Dependencias instaladas.
) else (
    echo Dependencias ya instaladas.
)
echo.

:: ========================================
:: 3. VERIFICAR E INSTALAR ZEROTIER
:: ========================================
echo [3/5] Verificando ZeroTier...
:check_zerotier
where zerotier-cli >nul 2>&1
if %errorlevel% NEQ 0 (
    echo ZeroTier no encontrado.
    echo.
    echo ========================================
    echo  INSTALE ZEROTIER MANUALMENTE
    echo ========================================
    echo.
    echo 1. Se abrira la pagina de descarga
    echo 2. Descargue e instale ZeroTier
    echo 3. Presione cualquier tecla cuando termine
    echo.
    start https://www.zerotier.com/download/
    echo.
    pause >nul
    goto check_zerotier
)
echo ZeroTier instalado correctamente.
echo.

:: ========================================
:: 3.5 PAUSA PARA DEPURACION
:: ========================================
echo [DEBUG] Presione una tecla para continuar...
pause >nul

:: ========================================
:: 4. INICIAR ZEROTIER Y CONECTAR A RED
:: ========================================
echo [4/5] Conectando a la red ZeroTier...
set ZT_NETWORK=b103a835d2d2727e

echo Verificando servicio de ZeroTier...
sc query "ZeroTierOneService" | findstr "RUNNING" >nul
if %errorlevel% NEQ 0 (
    echo Iniciando servicio de ZeroTier...
    net start "ZeroTierOneService" >nul 2>&1
    timeout /t 3 /nobreak >nul
)

echo Ejecutando join...
cmd /c "zerotier-cli join %ZT_NETWORK%" 2>&1
echo.
echo Codigo de error: %errorlevel%

if %errorlevel% NEQ 0 (
    echo.
    echo ERROR: ZeroTier necesita permisos de administrador.
    echo Ejecute este .bat como administrador (clic derecho -> Ejecutar como administrador)
    pause
    exit /b 1
)
echo.
echo Presione una tecla para continuar...
pause >nul

echo.
echo Obteniendo IP de ZeroTier...
echo.

:: Obtener la IP usando un metodo mas simple
zerotier-cli listnetworks > "%temp%\zt_networks.txt" 2>&1
type "%temp%\zt_networks.txt"

:: Extraer la IP (token 3 de la linea que contiene el network ID)
for /f "tokens=3" %%a in ('type "%temp%\zt_networks.txt" ^| findstr "%ZT_NETWORK%"') do set ZT_IP=%%a

echo.
echo IP obtenida: [%ZT_IP%]

if "%ZT_IP%"=="" (
    echo [ERROR] No se pudo obtener la IP.
    echo Verifique que ZeroTier este conectado a la red %ZT_NETWORK%
    pause
    exit /b 1
)

echo.
echo ========================================
echo    IP ZEROTIER: %ZT_IP%
echo ========================================
echo.
echo Conecte la app a: http://%ZT_IP%:8080
echo.
echo Presione una tecla para iniciar el servidor...
pause >nul

echo [5/5] Iniciando servidor...
node index.js
pause

echo.
echo ========================================
echo    IP ZEROTIER: %ZT_IP%
echo ========================================
echo.
echo Conecte la app a: http://%ZT_IP%:8080
echo.
echo Presione una tecla para iniciar el servidor...
pause >nul

echo [5/5] Iniciando servidor...
node index.js
pause
