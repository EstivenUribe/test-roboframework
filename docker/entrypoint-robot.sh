#!/bin/bash
set -e

echo "================================================================"
echo "  Biblioteca Pro — Robot Framework"
echo "================================================================"

# ── Generate fresh Excel test data ───────────────────────────────────────────
echo "[INFO] Generando datos_prueba.xlsx..."
python /app/robot/data/generar_datos.py

# ── Build robot arguments ─────────────────────────────────────────────────────
ROBOT_ARGS=(
    "--outputdir" "/app/robot/results"
    "--loglevel"  "${LOGLEVEL:-INFO}"
    "--variable"  "HEADLESS:true"
    "--variable"  "RECORD_VIDEO:false"
)

# Include tag filter if provided (e.g. TAGS=smoke)
if [ -n "${TAGS}" ]; then
    ROBOT_ARGS+=("--include" "${TAGS}")
fi

# Suite target: a specific .robot file path or the full tests directory
if [ -n "${SUITE}" ]; then
    TARGET="/app/robot/tests/${SUITE}"
else
    TARGET="/app/robot/tests/"
fi

echo "[INFO] Configuración:"
echo "       LOGLEVEL     = ${LOGLEVEL:-INFO}"
echo "       TAGS         = ${TAGS:-(sin filtro)}"
echo "       SUITE        = ${SUITE:-(todas)}"
echo "       TARGET       = ${TARGET}"
echo "----------------------------------------------------------------"

exec python -m robot "${ROBOT_ARGS[@]}" "${TARGET}"
