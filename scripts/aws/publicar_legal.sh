#!/usr/bin/env bash
# Genera el sitio legal desde docs/legal/*.md y lo sube al CDN.
#
# Uso:  scripts/aws/publicar_legal.sh              # genera y simula subida
#       DE_VERDAD=1 scripts/aws/publicar_legal.sh  # sube de verdad
#
# Se niega a publicar si los textos aún tienen datos de demostración.
source "$(dirname "$0")/comun.sh"
requiere pandoc

ORIGEN="$RAIZ/docs/legal"
SITIO="$RAIZ/build/sitio-legal"
rm -rf "$SITIO" && mkdir -p "$SITIO"

if grep -nE 'demo@bluetalk\.app|dirección de demostración' "$ORIGEN"/*.md; then
  echo "BLOQUEADO: hay datos de demostración (arriba). Pon el correo real." >&2
  [[ "${DE_VERDAD:-0}" == "1" ]] && exit 1
  echo "(Simulación: se sigue para revisar el HTML, pero no se publicaría.)"
fi

pagina() { # $1 = md de origen, $2 = html de salida, $3 = título
  pandoc "$ORIGEN/$1" --standalone --metadata "title=$3" \
    --metadata lang=es --css estilo.css -o "$SITIO/$2"
}
pagina PRIVACIDAD.md privacidad.html "Política de privacidad de BlueTalk"
pagina TERMINOS_Y_CONDICIONES.md terminos.html "Términos de BlueTalk"
cp "$RAIZ/infra/aws/sitio/"{index.html,estilo.css} "$SITIO/"
echo "Sitio generado en $SITIO"

BUCKET="$(salida_pila Bucket)"
DIST="$(salida_pila DistribucionId)"
# Sin --delete a propósito: /paquetes/ vive en el mismo bucket.
ejecutar aws s3 sync "$SITIO" "s3://$BUCKET/" \
  --cache-control "public, max-age=3600"
ejecutar aws cloudfront create-invalidation --distribution-id "$DIST" \
  --paths "/index.html" "/privacidad.html" "/terminos.html" "/estilo.css"
echo "URL para Play Console: $(salida_pila UrlBase)/privacidad.html"
