#!/usr/bin/env bash
# Corre la suite por partes, con prioridad baja y 2 hilos (máquina compartida).
#
# Uso:  scripts/test-por-partes.sh            # todas las partes, en orden
#       scripts/test-por-partes.sh base       # solo una parte
#       scripts/test-por-partes.sh --lista    # ver las partes
#
# Mismo resultado que `flutter test`, pero si una parte falla se sabe cuál
# y se puede repetir sola sin volver a pagar el resto.
set -euo pipefail
cd "$(dirname "$0")/.."

declare -A PARTES=(
  [base]="test/arquitectura test/core test/data test/widget_test.dart"
  [comunicador]="test/comunicador test/features"
  [juegos]="test/juegos"
  [rutinas]="test/rutinas test/recordatorios"
  [padre]="test/padre"
)
ORDEN=(base comunicador juegos rutinas padre)

if [[ "${1:-}" == "--lista" ]]; then
  for p in "${ORDEN[@]}"; do echo "$p: ${PARTES[$p]}"; done; exit 0
fi
if [[ -n "${1:-}" && -z "${PARTES[${1}]+x}" ]]; then
  echo "Parte desconocida: $1 (usa --lista)" >&2; exit 2
fi

# Comprobación: ninguna carpeta de test/ queda fuera de las partes.
for d in test/*/; do
  [[ " ${PARTES[*]} " == *" ${d%/} "* ]] || { echo "Falta en PARTES: ${d%/}" >&2; exit 2; }
done

for p in ${1:-${ORDEN[@]}}; do
  echo "== $p"
  # shellcheck disable=SC2086
  nice -n 15 flutter test --concurrency=2 ${PARTES[$p]} 2>&1 | tail -1
  [[ ${PIPESTATUS[0]} -eq 0 ]] || { echo "FALLA en la parte '$p'"; exit 1; }
done
