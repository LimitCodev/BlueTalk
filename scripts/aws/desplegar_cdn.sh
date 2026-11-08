#!/usr/bin/env bash
# Crea o actualiza la pila del CDN (infra/aws/cdn.yaml).
#
# Uso:  scripts/aws/desplegar_cdn.sh [correo-alertas]        # simulación
#       DE_VERDAD=1 scripts/aws/desplegar_cdn.sh tu@correo   # real
source "$(dirname "$0")/comun.sh"

CORREO="${1:-}"
[[ "${DE_VERDAD:-0}" == "1" ]] && requiere aws

ejecutar aws cloudformation deploy \
  --region "$REGION" \
  --stack-name "$PILA" \
  --template-file "$RAIZ/infra/aws/cdn.yaml" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides "CorreoAlertas=$CORREO" \
  --no-fail-on-empty-changeset

echo "Siguiente: scripts/aws/publicar_legal.sh"
