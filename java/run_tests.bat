@echo off
chcp 65001 >nul
title Biblioteca Pro - Java Selenium

cd /d "%~dp0"

echo.
echo ==========================================================
echo   BIBLIOTECA PRO - Java Selenium / TestNG
echo ==========================================================
echo.
echo   Parametros de entorno (set antes de ejecutar):
echo     HEADLESS=true^|false   (default: false)
echo     TEST=NombreClase       (default: suite completa via testng.xml)
echo.
echo   Ejemplos:
echo     run_tests.bat
echo     set HEADLESS=true ^&^& run_tests.bat
echo     set TEST=AuthTests ^&^& run_tests.bat
echo.

REM ── Valores por defecto ───────────────────────────────────────────────────
if "%HEADLESS%"==""  set HEADLESS=false
if "%TEST%"==""      set TEST=

REM ── Verificar Java ────────────────────────────────────────────────────────
where java >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Java JDK 11+ no encontrado en el PATH.
    echo         Descarga desde: https://adoptium.net/
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do echo [OK] %%v

REM ── Buscar Maven (PATH → instalaciones conocidas) ─────────────────────────
set MVN_CMD=
where mvn >nul 2>&1
if %ERRORLEVEL%==0 (
    set MVN_CMD=mvn
) else if exist "C:\maven\apache-maven-3.9.6\bin\mvn.cmd" (
    set MVN_CMD=C:\maven\apache-maven-3.9.6\bin\mvn.cmd
    set "PATH=C:\maven\apache-maven-3.9.6\bin;%PATH%"
) else if exist "C:\maven\bin\mvn.cmd" (
    set MVN_CMD=C:\maven\bin\mvn.cmd
    set "PATH=C:\maven\bin;%PATH%"
) else if exist "%USERPROFILE%\scoop\apps\maven\current\bin\mvn.cmd" (
    set MVN_CMD=%USERPROFILE%\scoop\apps\maven\current\bin\mvn.cmd
)

if "%MVN_CMD%"=="" (
    echo [ERROR] Maven 3.8+ no encontrado.
    echo.
    echo   Opcion A - winget (recomendado):
    echo     winget install Apache.Maven
    echo.
    echo   Opcion B - Chocolatey:
    echo     choco install maven
    echo.
    echo   Opcion C - Manual:
    echo     1. Descarga: https://maven.apache.org/download.cgi
    echo     2. Extrae en C:\maven
    echo     3. Agrega C:\maven\bin al PATH del sistema
    echo.
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('"%MVN_CMD%" -version 2^>^&1 ^| findstr /i "Apache Maven"') do echo [OK] %%v

REM ── Excel de datos ────────────────────────────────────────────────────────
if not exist src\test\resources\datos_prueba.xlsx (
    echo [INFO] Excel de datos no encontrado. Buscando fuente...
    if exist ..\robot\data\datos_prueba.xlsx (
        copy /Y ..\robot\data\datos_prueba.xlsx src\test\resources\datos_prueba.xlsx >nul
        echo [OK] Excel copiado desde robot\data\
    ) else (
        echo [INFO] Generando Excel con Python...
        where python >nul 2>&1
        if %ERRORLEVEL%==0 (
            python ..\robot\data\generar_datos.py
            if exist ..\robot\data\datos_prueba.xlsx (
                copy /Y ..\robot\data\datos_prueba.xlsx src\test\resources\datos_prueba.xlsx >nul
                echo [OK] Excel generado y copiado.
            ) else (
                echo [WARN] No se pudo generar el Excel automaticamente.
            )
        ) else (
            echo [WARN] Python no encontrado. Genera el Excel manualmente:
            echo        cd robot ^& python data\generar_datos.py
        )
    )
) else (
    echo [OK] datos_prueba.xlsx ya existe.
)

REM ── Carpetas de artefactos ────────────────────────────────────────────────
if not exist target\screenshots    mkdir target\screenshots
if not exist target\videos         mkdir target\videos
if not exist target\extent-reports mkdir target\extent-reports
echo [OK] Carpetas de artefactos listas.

echo.
echo [INFO] Configuracion de ejecucion:
echo   Headless : %HEADLESS%
if not "%TEST%"=="" echo   Test     : %TEST%
echo.

REM ── Modo headless ─────────────────────────────────────────────────────────
if "%HEADLESS%"=="true" (
    echo [INFO] HEADLESS=true: Chrome se abrira sin ventana ^(--headless=new^).
    echo.
)

REM ── Seleccionar archivo de suite TestNG ───────────────────────────────────
set TESTNG_FILE=testng.xml
if "%HEADLESS%"=="true" if exist testng-headless.xml set TESTNG_FILE=testng-headless.xml

REM ── Compilar y ejecutar ────────────────────────────────────────────────────
echo [INFO] Compilando y ejecutando con Maven...
echo [INFO] (Primera vez puede tardar varios minutos descargando dependencias)
echo.

if "%TEST%"=="" (
    "%MVN_CMD%" test ^
      "-Dfile.encoding=UTF-8" ^
      "-Dsurefire.useFile=false" ^
      "-Dsurefire.suiteXmlFiles=%TESTNG_FILE%"
) else (
    "%MVN_CMD%" test ^
      "-Dfile.encoding=UTF-8" ^
      "-Dsurefire.useFile=false" ^
      "-Dtest=%TEST%"
)

set RC=%ERRORLEVEL%

echo.
if %RC%==0 (
    echo [OK] Suite completada: TODOS LOS TESTS PASARON.
) else (
    echo [!!] Suite completada: ALGUNOS TESTS FALLARON ^(rc=%RC%^).
    echo      Revisa el reporte para ver los detalles.
)
echo.
echo  Reporte ExtentReports : %~dp0target\extent-reports\
echo  Reporte Surefire      : %~dp0target\surefire-reports\
echo  Capturas              : %~dp0target\screenshots\
echo  Videos GIF            : %~dp0target\videos\
echo.
pause
exit /b %RC%
