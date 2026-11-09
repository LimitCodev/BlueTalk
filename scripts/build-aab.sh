#!/usr/bin/env bash
# AAB de release para Google Play (Play exige AAB para apps nuevas).
#
# Uso:  ./scripts/build-aab.sh
#
# - Comprueba la firma ANTES de compilar: sin keystore, Gradle tarda
#   minutos en fallar con `validateSigningRelease` (requisitosPlayStore §3.2).
# - --obfuscate + --split-debug-info: el Dart queda ofuscado y los símbolos
#   salen del binario (AAB más pequeño). Los símbolos se guardan en
#   dist/simbolos/<versión>/ (fuera del repo): sin ellos no se pueden leer
#   los errores de esa versión (`flutter symbolize`). Guárdalos con el keystore.
# - Mismos límites duros que scripts/gradle-limite.sh (4 CPU, 6 GB, prioridad
#   baja): la máquina es compartida con otros agentes.
set -euo pipefail
cd "$(dirname "$0")/.."

PROPS=android/key.properties
if [[ ! -f "$PROPS" ]]; then
  echo "BLOQUEADO: falta $PROPS (firma de release). Ver docs/informes/decisiones-pendientes.md" >&2
  exit 1
fi
TIENDA=$(sed -n 's/^storeFile=//p' "$PROPS")
TIENDA="${TIENDA/#\~/$HOME}"
if [[ ! -f "$TIENDA" ]]; then
  echo "BLOQUEADO: el keystore no existe en '$TIENDA'. Restaura tu copia." >&2
  exit 1
fi

VERSION=$(sed -n 's/^version: *//p' pubspec.yaml)
SIMBOLOS="dist/simbolos/$VERSION"
mkdir -p "$SIMBOLOS"

systemd-run --user --scope -p CPUQuota=400% -p MemoryMax=6G \
  nice -n 10 flutter build appbundle --release --flavor play \
  --obfuscate --split-debug-info="$SIMBOLOS"

AAB=build/app/outputs/bundle/playRelease/app-play-release.aab
cp "$AAB" "dist/BlueTalk-$VERSION.aab"
echo "AAB: dist/BlueTalk-$VERSION.aab ($(du -h "$AAB" | cut -f1))"
echo "sha256: $(sha256sum "$AAB" | cut -d' ' -f1)"
echo "Símbolos: $SIMBOLOS (no se suben al repo; guárdalos)"
