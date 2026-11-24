#!/usr/bin/env bash
# Arma la landing de descarga de la beta en build/landing-beta/ y,
# con --servir, la publica en la red local para escanear el QR.
#
# Uso:  ./scripts/landing-beta.sh [URL_PUBLICA] [--servir]
#   Sin URL usa http://<IP de la LAN>:8080/ (el teléfono debe estar en la
#   misma wifi). El QR apunta siempre a la URL de la landing, no al APK.
#   APK_URL=<enlace> cambia el destino del botón (por defecto, el APK local).
# Requiere: dist/BlueTalk.apk (./scripts/build-apk.sh) y qrencode.
set -euo pipefail
cd "$(dirname "$0")/.."

PUERTO=8080
SERVIR=0
URL=""
for arg in "$@"; do
  case "$arg" in
    --servir) SERVIR=1 ;;
    *) URL="$arg" ;;
  esac
done
if [[ -z "$URL" ]]; then
  IP=$(ip -4 route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')
  URL="http://$IP:$PUERTO/"
fi

APK=dist/BlueTalk.apk
[[ -f "$APK" ]] || { echo "Falta $APK: ejecuta ./scripts/build-apk.sh" >&2; exit 1; }

OUT=build/landing-beta
rm -rf "$OUT"
mkdir -p "$OUT"
cp infra/beta/index.html infra/beta/ruleta.html "$OUT/"
cp -r infra/beta/img "$OUT/"
cp assets/brand/logo_bluetalk.png "$OUT/logo.png"
cp assets/mascota/ave_saluda_tablero.png "$OUT/mascota.png"
cp assets/mascota/ave_pensando.png "$OUT/mascota-pensando.png"
cp assets/mascota/ave_alas_abiertas.png "$OUT/mascota-ruleta.png"
cp assets/mascota/ave_bandera.png "$OUT/mascota-premio.png"
cp assets/fonts/Nunito-Variable.ttf "$OUT/"
cp "$APK" "$OUT/BlueTalk-beta.apk"
qrencode -t SVG -m 2 -s 8 -o "$OUT/qr.svg" "$URL"

VERSION=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
SHA=$(sha256sum "$APK" | cut -d' ' -f1)
TAMANO=$(du -m "$APK" | cut -f1)
FECHA=$(date -r "$APK" +%d/%m/%Y)
sed -i \
  -e "s|{{VERSION}}|$VERSION|g" \
  -e "s|{{SHA256}}|$SHA|g" \
  -e "s|{{TAMANO}}|$TAMANO MB|g" \
  -e "s|{{FECHA}}|$FECHA|g" \
  -e "s|{{URL}}|${URL//&/\\&}|g" \
  -e "s|{{APK_URL}}|${APK_URL:-BlueTalk-beta.apk}|g" \
  "$OUT/index.html"

# Autocomprobación: no deben quedar marcadores sin reemplazar.
if grep -q '{{' "$OUT/index.html"; then
  echo "Quedan marcadores sin reemplazar en $OUT/index.html" >&2; exit 1
fi

echo "Landing lista en $OUT  (versión $VERSION, $TAMANO MB)"
echo "  URL del QR: $URL"
echo "  sha256: $SHA"

if [[ $SERVIR == 1 ]]; then
  echo "Sirviendo en el puerto $PUERTO (Ctrl+C para parar)…"
  exec python3 -m http.server "$PUERTO" --bind 0.0.0.0 --directory "$OUT"
fi
