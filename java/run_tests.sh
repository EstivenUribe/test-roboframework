#!/usr/bin/env bash
# run_tests.sh — Java Selenium / TestNG runner (Linux / macOS)
# Uso:
#   chmod +x run_tests.sh
#   ./run_tests.sh
#   HEADLESS=true ./run_tests.sh
#   TEST=AuthTests ./run_tests.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Valores por defecto ────────────────────────────────────────────────────
HEADLESS="${HEADLESS:-false}"
TEST="${TEST:-}"

echo ""
echo "=========================================================="
echo "  BIBLIOTECA PRO - Java Selenium / TestNG"
echo "=========================================================="
echo ""

# ── Java ───────────────────────────────────────────────────────────────────
if ! command -v java &>/dev/null; then
    echo "[ERROR] Java JDK 11+ no encontrado."
    echo "        macOS:  brew install --cask temurin"
    echo "        Ubuntu: sudo apt install default-jdk"
    exit 1
fi
echo "[OK] $(java -version 2>&1 | head -1)"

# ── Maven ──────────────────────────────────────────────────────────────────
MVN_CMD=""
for candidate in mvn \
    "$HOME/.sdkman/candidates/maven/current/bin/mvn" \
    "/usr/local/bin/mvn" \
    "/opt/homebrew/bin/mvn"; do
    if command -v "$candidate" &>/dev/null 2>&1; then
        MVN_CMD="$candidate"
        break
    fi
done

if [ -z "$MVN_CMD" ]; then
    echo "[ERROR] Maven 3.8+ no encontrado."
    echo "  macOS:  brew install maven"
    echo "  Ubuntu: sudo apt install maven"
    echo "  sdkman: sdk install maven"
    exit 1
fi
echo "[OK] $("$MVN_CMD" -version | head -1)"

# ── Excel de datos ─────────────────────────────────────────────────────────
if [ ! -f src/test/resources/datos_prueba.xlsx ]; then
    echo "[INFO] Excel de datos no encontrado. Buscando fuente..."
    if [ -f ../robot/data/datos_prueba.xlsx ]; then
        cp ../robot/data/datos_prueba.xlsx src/test/resources/datos_prueba.xlsx
        echo "[OK] Excel copiado desde robot/data/"
    else
        PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo "")
        if [ -n "$PYTHON" ]; then
            echo "[INFO] Generando Excel con Python..."
            "$PYTHON" ../robot/data/generar_datos.py
            cp ../robot/data/datos_prueba.xlsx src/test/resources/datos_prueba.xlsx
            echo "[OK] Excel generado y copiado."
        else
            echo "[WARN] Python no encontrado. Genera el Excel manualmente:"
            echo "       cd robot && python data/generar_datos.py"
        fi
    fi
else
    echo "[OK] datos_prueba.xlsx ya existe."
fi

# ── Carpetas de artefactos ─────────────────────────────────────────────────
mkdir -p target/screenshots target/videos target/extent-reports
echo "[OK] Carpetas de artefactos listas."

echo ""
echo "[INFO] Configuracion de ejecucion:"
echo "  Headless : $HEADLESS"
[ -n "$TEST" ] && echo "  Test     : $TEST"
echo ""

# ── Nota headless ──────────────────────────────────────────────────────────
if [ "$HEADLESS" = "true" ]; then
    echo "[NOTA] HEADLESS=true detectado."
    echo "       Requiere descomentar --headless=new en BaseTest.java para CI."
    echo ""
fi

# ── Suite TestNG ───────────────────────────────────────────────────────────
TESTNG_FILE="testng.xml"
if [ "$HEADLESS" = "true" ] && [ -f "testng-headless.xml" ]; then
    TESTNG_FILE="testng-headless.xml"
fi

# ── Compilar y ejecutar ────────────────────────────────────────────────────
echo "[INFO] Compilando y ejecutando con Maven..."
echo ""

if [ -z "$TEST" ]; then
    "$MVN_CMD" test \
      -Dfile.encoding=UTF-8 \
      -Dsurefire.useFile=false \
      -Dsurefire.suiteXmlFiles="$TESTNG_FILE"
else
    "$MVN_CMD" test \
      -Dfile.encoding=UTF-8 \
      -Dsurefire.useFile=false \
      -Dtest="$TEST"
fi

RC=$?

echo ""
if [ $RC -eq 0 ]; then
    echo "[OK] Suite completada: TODOS LOS TESTS PASARON."
else
    echo "[!!] Suite completada: ALGUNOS TESTS FALLARON (rc=$RC)."
    echo "     Revisa el reporte para ver los detalles."
fi
echo ""
echo "  Reporte ExtentReports : ${SCRIPT_DIR}/target/extent-reports/"
echo "  Reporte Surefire      : ${SCRIPT_DIR}/target/surefire-reports/"
echo "  Capturas              : ${SCRIPT_DIR}/target/screenshots/"
echo "  Videos GIF            : ${SCRIPT_DIR}/target/videos/"
echo ""
exit $RC
