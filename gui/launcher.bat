@echo off
chcp 65001 >nul
title Biblioteca Pro - Politécnico Colombiano

cd /d "%~dp0"

echo.
echo  Politecnico Colombiano Jaime Isaza Cadavid
echo  Pruebas y Gestion de la Configuracion
echo  ==========================================
echo.

REM ── Python ────────────────────────────────────────────────────────────────
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Python no encontrado. Descarga Python 3.9+ desde python.org
    pause & exit /b 1
)

REM ── Pillow (para previsualizar capturas) ──────────────────────────────────
python -c "from PIL import Image" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [INFO] Instalando Pillow...
    pip install -q Pillow
)

REM ── Maven en PATH ─────────────────────────────────────────────────────────
where mvn >nul 2>&1
if %ERRORLEVEL% neq 0 (
    if exist "C:\maven\apache-maven-3.9.6\bin\mvn.cmd" (
        set "PATH=C:\maven\apache-maven-3.9.6\bin;%PATH%"
        echo [OK] Maven cargado desde C:\maven\apache-maven-3.9.6\bin
    )
)

REM ── Lanzar GUI ────────────────────────────────────────────────────────────
echo [INFO] Iniciando interfaz grafica...
start "" pythonw "%~dp0launcher.py"
if %ERRORLEVEL% neq 0 (
    python "%~dp0launcher.py"
)
