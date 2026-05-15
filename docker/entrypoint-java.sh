#!/bin/bash
set -e

echo "================================================================"
echo "  Biblioteca Pro — Java / TestNG"
echo "================================================================"

cd /app/java

# ── Build Maven arguments ─────────────────────────────────────────────────────
MVN_ARGS=(
    "test"
    "-Dfile.encoding=UTF-8"
    "-Dsurefire.useFile=false"
    "--no-transfer-progress"
    "-Dheadless=true"
)

# Run a specific class if provided (e.g. TEST_CLASS=AuthTests)
if [ -n "${TEST_CLASS}" ]; then
    MVN_ARGS+=("-Dtest=${TEST_CLASS}")
    echo "[INFO] Modo: clase única → ${TEST_CLASS}"
else
    MVN_ARGS+=("-Dsurefire.suiteXmlFiles=${TESTNG_FILE:-testng.xml}")
    echo "[INFO] Modo: suite → ${TESTNG_FILE:-testng.xml}"
fi

echo "[INFO] Headless : true (forzado en Docker)"
echo "----------------------------------------------------------------"

exec mvn "${MVN_ARGS[@]}"
