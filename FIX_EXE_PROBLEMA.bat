@echo off
setlocal EnableDelayedExpansion
echo ========================================
echo SOLUCION AUTOMATICA - PROBLEMA .EXE
echo ========================================
echo.

echo Paso 1: Copiando archivos .cc desde Flutter cache...
xcopy "C:\Users\koezg\flutter\bin\cache\artifacts\engine\windows-x64\cpp_client_wrapper\*.cc"
      "D:\proyectos\DYDAndroid\windows\flutter\ephemeral\cpp_client_wrapper\" /Y /I

echo.
echo Verificando archivos copiados...
dir "D:\proyectos\DYDAndroid\windows\flutter\ephemeral\cpp_client_wrapper\*.cc"

echo.
echo Paso 2: Compilando .EXE en modo release...
cd /d D:\proyectos\DYDAndroid
flutter build windows --release

echo.
echo ========================================
echo SOLUCION COMPLETADA
echo ========================================
echo.
echo Archivos generados:
echo   APK: D:\proyectos\DYDAndroid\build\app\outputs\flutter-apk\app-release.apk
echo   EXE: D:\proyectos\DYDAndroid\build\windows\x64\runner\Release\dyd_app.exe
echo.
echo Presiona ENTER para terminar...
pause >nul
