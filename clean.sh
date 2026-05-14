#!/usr/bin/env bash
# Limpia artefactos generados por las suites de prueba.
# No borra código fuente, venv, ni el Excel de datos.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "[LIMPIEZA] Artefactos Robot Framework..."
rm -rf "$ROOT/robot/results/screenshots/"* 2>/dev/null || true
rm -rf "$ROOT/robot/results/logs/"*         2>/dev/null || true
rm -rf "$ROOT/robot/results/videos/"*       2>/dev/null || true
rm -rf "$ROOT/robot/results/dryrun"         2>/dev/null || true

echo "[LIMPIEZA] Artefactos Java/Maven..."
rm -rf "$ROOT/java/target"

echo "[LIMPIEZA] Cachés Python..."
find "$ROOT/robot" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find "$ROOT/robot" -name "*.pyc" -delete 2>/dev/null || true

echo ""
echo "[OK] Limpieza completada."
echo "     Para regenerar el Excel de datos:"
echo "       robot/venv/bin/python robot/data/generar_datos.py"
echo "     Para reinstalar dependencias Python:"
echo "       cd robot && python -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
echo "     Para recompilar Java:"
echo "       cd java && mvn test-compile"
