@echo off
:: Limpia artefactos generados por las suites de prueba.
:: No borra codigo fuente, venv, ni el Excel de datos.
setlocal

set ROOT=%~dp0

echo [LIMPIEZA] Artefactos Robot Framework...
if exist "%ROOT%robot\results\screenshots" (
    for /d %%D in ("%ROOT%robot\results\screenshots\*") do rd /s /q "%%D" 2>nul
    del /q "%ROOT%robot\results\screenshots\*.*" 2>nul
)
if exist "%ROOT%robot\results\logs" (
    del /q "%ROOT%robot\results\logs\*.*" 2>nul
)
if exist "%ROOT%robot\results\videos" (
    del /q "%ROOT%robot\results\videos\*.*" 2>nul
)
if exist "%ROOT%robot\results\dryrun" (
    rd /s /q "%ROOT%robot\results\dryrun" 2>nul
)

echo [LIMPIEZA] Artefactos Java/Maven...
if exist "%ROOT%java\target" (
    rd /s /q "%ROOT%java\target"
)

echo [LIMPIEZA] Cachés Python...
for /r "%ROOT%robot" %%D in (__pycache__) do (
    if exist "%%D" rd /s /q "%%D" 2>nul
)
del /s /q "%ROOT%robot\*.pyc" 2>nul

echo.
echo [OK] Limpieza completada.
echo      Para regenerar el Excel de datos:
echo        robot\venv\Scripts\python.exe robot\data\generar_datos.py
echo      Para reinstalar dependencias Python:
echo        cd robot ^&^& python -m venv venv ^&^& venv\Scripts\activate ^&^& pip install -r requirements.txt
echo      Para recompilar Java:
echo        cd java ^&^& mvn test-compile

endlocal
