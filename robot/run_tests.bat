@echo off
chcp 65001 >nul
title Biblioteca Pro - Robot Framework

cd /d "%~dp0"

echo.
echo ==========================================================
echo   BIBLIOTECA PRO - Robot Framework Test Suite
echo ==========================================================
echo.
echo   Parametros de entorno (set antes de ejecutar):
echo     HEADLESS=true^|false     (default: false)
echo     RECORD_VIDEO=true^|false  (default: false)
echo     SUITE=tests\XX.robot     (default: suite completa)
echo     TAGS=tag1                (default: sin filtro de tags)
echo.

REM ── Valores por defecto ───────────────────────────────────────────────────
if "%HEADLESS%"==""     set HEADLESS=false
if "%RECORD_VIDEO%"=""  set RECORD_VIDEO=false
if "%SUITE%"==""        set SUITE=tests

REM ── Verificar Python ──────────────────────────────────────────────────────
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python 3.9+ no encontrado en el PATH.
    echo         Descarga desde: https://www.python.org/downloads/
    pause & exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do echo [OK] %%v

REM ── Entorno virtual ───────────────────────────────────────────────────────
if not exist venv\Scripts\activate.bat (
    echo [INFO] Creando entorno virtual...
    python -m venv venv
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] No se pudo crear el entorno virtual.
        pause & exit /b 1
    )
    echo [OK] Entorno virtual creado.
)
call venv\Scripts\activate.bat
echo [OK] Entorno virtual activado.

REM ── Dependencias Python ───────────────────────────────────────────────────
echo [INFO] Verificando dependencias Python...
pip install -q -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Fallo instalando dependencias. Revisa requirements.txt
    pause & exit /b 1
)
echo [OK] Dependencias OK.

REM ── Excel de datos ────────────────────────────────────────────────────────
if not exist data\datos_prueba.xlsx (
    echo [INFO] Generando datos de prueba...
    python data\generar_datos.py
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] Fallo generando el Excel. Revisa data\generar_datos.py
        pause & exit /b 1
    )
    echo [OK] datos_prueba.xlsx generado.
) else (
    echo [OK] datos_prueba.xlsx ya existe.
)

REM ── Carpetas de resultados ────────────────────────────────────────────────
if not exist results\logs        mkdir results\logs
if not exist results\screenshots mkdir results\screenshots
if not exist results\videos      mkdir results\videos
echo [OK] Carpetas de resultados listas.

echo.
echo [INFO] Configuracion de ejecucion:
echo   Suite       : %SUITE%
echo   Headless    : %HEADLESS%
echo   Grabar vid. : %RECORD_VIDEO%
if not "%TAGS%"=="" echo   Tags        : %TAGS%
echo.

REM ── Seleccionar ejecutable robot ──────────────────────────────────────────
set ROBOT_EXE=venv\Scripts\robot.exe
if not exist %ROBOT_EXE% set ROBOT_EXE=robot

REM ── Argumentos de tags opcionales ────────────────────────────────────────
set TAG_ARGS=
if not "%TAGS%"=="" set TAG_ARGS=--include %TAGS%

REM ── Ejecucion ─────────────────────────────────────────────────────────────
echo [INFO] Ejecutando Robot Framework...
echo.

%ROBOT_EXE% ^
  --outputdir  results\logs ^
  --pythonpath resources ^
  --log        log.html ^
  --report     report.html ^
  --variable   BROWSER:chrome ^
  --variable   HEADLESS:%HEADLESS% ^
  --variable   RECORD_VIDEO:%RECORD_VIDEO% ^
  --variable   SCREENSHOTS_DIR:%~dp0results\screenshots ^
  --variable   VIDEOS_DIR:%~dp0results\videos ^
  --loglevel   INFO ^
  %TAG_ARGS% ^
  %SUITE%

set RC=%ERRORLEVEL%

echo.
if %RC%==0 (
    echo [OK] Suite completada: TODOS LOS TESTS PASARON.
) else (
    echo [!!] Suite completada: ALGUNOS TESTS FALLARON ^(rc=%RC%^).
    echo      Revisa el reporte para ver los detalles.
)
echo.
echo  Reporte  : %~dp0results\logs\report.html
echo  Log      : %~dp0results\logs\log.html
echo  Capturas : %~dp0results\screenshots\
echo  Videos   : %~dp0results\videos\
echo.
pause
exit /b %RC%
