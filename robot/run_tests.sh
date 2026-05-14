#!/usr/bin/env bash
# run_tests.sh — Robot Framework test runner (Linux / macOS)
# Uso:
#   chmod +x run_tests.sh
#   ./run_tests.sh
#   HEADLESS=true ./run_tests.sh
#   SUITE=tests/01_autenticacion.robot ./run_tests.sh
#   TAGS=smoke ./run_tests.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Valores por defecto ────────────────────────────────────────────────────
HEADLESS="${HEADLESS:-false}"
RECORD_VIDEO="${RECORD_VIDEO:-false}"
SUITE="${SUITE:-tests}"
TAGS="${TAGS:-}"

echo ""
echo "=========================================================="
echo "  BIBLIOTECA PRO - Robot Framework Test Suite"
echo "=========================================================="
echo ""

# ── Python ─────────────────────────────────────────────────────────────────
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "[ERROR] Python 3.9+ no encontrado."
    echo "        Instala desde: https://www.python.org/downloads/"
    exit 1
fi
echo "[OK] $("$PYTHON" --version)"

# ── Entorno virtual ────────────────────────────────────────────────────────
if [ ! -f venv/bin/activate ]; then
    echo "[INFO] Creando entorno virtual..."
    "$PYTHON" -m venv venv
    echo "[OK] Entorno virtual creado."
fi
# shellcheck disable=SC1091
source venv/bin/activate
echo "[OK] Entorno virtual activado."

# ── Dependencias ───────────────────────────────────────────────────────────
echo "[INFO] Verificando dependencias Python..."
pip install -q -r requirements.txt
echo "[OK] Dependencias OK."

# ── Excel de datos ─────────────────────────────────────────────────────────
if [ ! -f data/datos_prueba.xlsx ]; then
    echo "[INFO] Generando datos de prueba..."
    "$PYTHON" data/generar_datos.py
    echo "[OK] datos_prueba.xlsx generado."
else
    echo "[OK] datos_prueba.xlsx ya existe."
fi

# ── Carpetas de resultados ─────────────────────────────────────────────────
mkdir -p results/logs results/screenshots results/videos
echo "[OK] Carpetas de resultados listas."

echo ""
echo "[INFO] Configuracion de ejecucion:"
echo "  Suite       : $SUITE"
echo "  Headless    : $HEADLESS"
echo "  Grabar vid. : $RECORD_VIDEO"
[ -n "$TAGS" ] && echo "  Tags        : $TAGS"
echo ""

# ── Ejecutable robot ────────────────────────────────────────────────────────
ROBOT_EXE="venv/bin/robot"
command -v "$ROBOT_EXE" &>/dev/null || ROBOT_EXE="robot"

# ── Argumentos de tags ──────────────────────────────────────────────────────
TAG_ARGS=()
if [ -n "$TAGS" ]; then
    TAG_ARGS=(--include "$TAGS")
fi

# ── Ejecucion ──────────────────────────────────────────────────────────────
echo "[INFO] Ejecutando Robot Framework..."
echo ""

"$ROBOT_EXE" \
  --outputdir  results/logs \
  --pythonpath resources \
  --log        log.html \
  --report     report.html \
  --variable   BROWSER:chrome \
  --variable   "HEADLESS:${HEADLESS}" \
  --variable   "RECORD_VIDEO:${RECORD_VIDEO}" \
  --variable   "SCREENSHOTS_DIR:${SCRIPT_DIR}/results/screenshots" \
  --variable   "VIDEOS_DIR:${SCRIPT_DIR}/results/videos" \
  --loglevel   INFO \
  "${TAG_ARGS[@]+"${TAG_ARGS[@]}"}" \
  "$SUITE"

RC=$?

echo ""
if [ $RC -eq 0 ]; then
    echo "[OK] Suite completada: TODOS LOS TESTS PASARON."
else
    echo "[!!] Suite completada: ALGUNOS TESTS FALLARON (rc=$RC)."
    echo "     Revisa el reporte para ver los detalles."
fi
echo ""
echo "  Reporte  : ${SCRIPT_DIR}/results/logs/report.html"
echo "  Log      : ${SCRIPT_DIR}/results/logs/log.html"
echo "  Capturas : ${SCRIPT_DIR}/results/screenshots/"
echo "  Videos   : ${SCRIPT_DIR}/results/videos/"
echo ""
exit $RC
