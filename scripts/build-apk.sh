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

# Nombre de reparto (docs/play/instalar-apk.md): el arm64-v8a es el de
# casi todos los móviles actuales y se publica como BlueTalk.apk.
mkdir -p dist
cp "$APK_DIR/app-arm64-v8a-release.apk" dist/BlueTalk.apk

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
echo "Para compartir: sube dist/BlueTalk.apk (arm64-v8a) y publica su"
echo "sha256 junto al enlace, tal como explica docs/play/instalar-apk.md:"
sha256sum dist/BlueTalk.apk | sed 's/^/  /'
echo
echo "Para instalar en un móvil con cable:"
echo "  adb install -r $APK_DIR/app-arm64-v8a-release.apk"
