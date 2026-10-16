#!/usr/bin/env bash
# Build de BlueTalk por arquitectura con hash SHA-256 (plan 13 P7.1 y 7.2).
#
# Uso:  ./scripts/build-apk.sh
# Sale con error si algo falla (set -e). El hash permite comprobar que el
# APK que recibió alguien es exactamente el que se publicó junto al enlace.
set -euo pipefail
cd "$(dirname "$0")/.."

flutter build apk --release --split-per-abi

APK_DIR="build/app/outputs/flutter-apk"
echo
echo "APKs de release (un APK por arquitectura):"
for apk in "$APK_DIR"/app-*-release.apk; do
  nombre=$(basename "$apk")
  tamano=$(du -h "$apk" | cut -f1)
  hash=$(sha256sum "$apk" | cut -d' ' -f1)
  echo "  $nombre  $tamano"
  echo "    sha256: $hash"
done
echo
echo "Para instalar en un móvil (con cable o descargando el archivo):"
echo "  adb install -r $APK_DIR/app-arm64-v8a-release.apk"
