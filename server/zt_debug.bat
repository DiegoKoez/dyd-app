@echo off
echo Verificando ZeroTier...
echo.
echo Salvando salida en archivo...
zerotier-cli listnetworks > "%temp%\zt_out.txt" 2>&1
echo Contenido del archivo:
type "%temp%\zt_out.txt"
echo.
echo Presione una tecla...
pause
echo.
echo Informacion de la red:
zerotier-cli get b103a835d2d2727e >> "%temp%\zt_out.txt" 2>&1
type "%temp%\zt_out.txt"
echo.
pause
