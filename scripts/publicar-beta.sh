#!/usr/bin/env bash
# Publica la landing de la beta (rama gh-pages, que sirven Vercel y
# GitHub Pages) y el APK como Release.
#
# Uso:  ./scripts/publicar-beta.sh
#   LANDING_URL=<url> cambia la URL del QR (por defecto, la de Vercel).
#   Vercel: proyecto importado desde este repo, rama de producción gh-pages,
#   preset «Other», sin comando de build; cada push redespliega solo.
# Repo público aparte (no el de BlueTalk). La landing va en la rama
# gh-pages; nunca se hace push a main. Volver a ejecutarlo actualiza la
# landing y reemplaza el APK de la release (el enlace no cambia).
# Requiere: gh con sesión iniciada y dist/BlueTalk.apk.
set -euo pipefail
cd "$(dirname "$0")/.."

REPO=LimitCodev/bluetalk-beta
DUENO=${REPO%%/*}
NOMBRE=${REPO##*/}
URL=${LANDING_URL:-"https://$NOMBRE.vercel.app/"}
VERSION=$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
TAG="v$VERSION-beta"

gh repo view "$REPO" >/dev/null 2>&1 || gh repo create "$REPO" --public \
  --description "Descarga directa de la beta de BlueTalk (AAC para niñas y niños autistas)"

APK_URL="https://github.com/$REPO/releases/latest/download/BlueTalk-beta.apk"
APK_URL=$APK_URL ./scripts/landing-beta.sh "$URL"

# Pages: todo menos el APK, que vive en la release. Sin push forzado:
# si la rama existe, se añade un commit encima.
REMOTO="https://github.com/$REPO.git"
PUB=build/landing-beta-pages
rm -rf "$PUB"
if git ls-remote --exit-code --heads "$REMOTO" gh-pages >/dev/null 2>&1; then
  git clone -q --depth 1 -b gh-pages "$REMOTO" "$PUB"
  find "$PUB" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
else
  mkdir -p "$PUB"
  git -C "$PUB" init -q -b gh-pages
fi
cp -r build/landing-beta/* "$PUB/"
rm "$PUB/BlueTalk-beta.apk"
touch "$PUB/.nojekyll"
git -C "$PUB" add -A
git -C "$PUB" diff --cached --quiet || git -C "$PUB" commit -q -m "Landing beta $VERSION"
git -C "$PUB" push -q "$REMOTO" gh-pages

gh api "repos/$REPO/pages" >/dev/null 2>&1 || gh api -X POST "repos/$REPO/pages" \
  -f "source[branch]=gh-pages" -f "source[path]=/" >/dev/null 2>&1 || true  # GitHub suele activarlo solo al recibir gh-pages

SHA=$(sha256sum dist/BlueTalk.apk | cut -d' ' -f1)
NOTAS="Beta de descarga directa. SHA-256 de BlueTalk-beta.apk: $SHA"
cp dist/BlueTalk.apk build/BlueTalk-beta.apk
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  gh release upload "$TAG" build/BlueTalk-beta.apk --clobber --repo "$REPO"
  gh release edit "$TAG" --notes "$NOTAS" --repo "$REPO" >/dev/null
else
  gh release create "$TAG" build/BlueTalk-beta.apk --repo "$REPO" \
    --target gh-pages --title "BlueTalk $VERSION beta" --notes "$NOTAS"
fi

echo "Publicado: $URL"
echo "APK: $APK_URL"
