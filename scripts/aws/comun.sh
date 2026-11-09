# Funciones comunes de scripts/aws/. Se carga con `source`, no se ejecuta.
#
# Seguridad por defecto: TODO es simulación. Solo con DE_VERDAD=1 se
# llama a AWS. Las credenciales las pone la persona (aws configure /
# AWS_PROFILE); ningún script las lee, guarda ni imprime.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PILA="${BLUETALK_PILA:-bluetalk-cdn}"
REGION="${AWS_REGION:-us-east-1}"

ejecutar() {
  if [[ "${DE_VERDAD:-0}" == "1" ]]; then
    "$@"
  else
    printf '[simulación]'; printf ' %q' "$@"; echo
  fi
}

# Valor de una salida de la pila (Bucket, DistribucionId, UrlBase).
salida_pila() {
  if [[ "${DE_VERDAD:-0}" != "1" ]]; then echo "<$1>"; return; fi
  aws cloudformation describe-stacks --region "$REGION" --stack-name "$PILA" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

requiere() {
  command -v "$1" >/dev/null || { echo "Falta '$1' instalado." >&2; exit 1; }
}
