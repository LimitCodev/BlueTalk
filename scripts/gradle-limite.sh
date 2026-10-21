#!/usr/bin/env bash
# Ejecuta Gradle con los límites duros del encargo (§0): 4 hilos, 6 GB, prioridad baja.
#
#   scripts/gradle-limite.sh build apk --debug
#   scripts/gradle-limite.sh testDebugUnitTest
set -euo pipefail

cd "$(dirname "$0")/.."

exec systemd-run --user --scope \
  -p CPUQuota=400% \
  -p MemoryMax=6G \
  nice -n 10 taskset -c 0-3 \
  ./gradlew "$@"
