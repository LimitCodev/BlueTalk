# P0-2 — Ruta A: edición Play sin VPN ni acceso al uso (2026-11-08)

Decisión del dueño. No se borró el filtro: sigue disponible para el APK directo
del piloto escolar.

## Qué cambió

| Edición | Comando | Contenido |
|---|---|---|
| `play` (por defecto) | `scripts/build-aab.sh` | Sin VPN, acceso al uso, servicio en primer plano ni `INTERNET` |
| `directa` | `scripts/build-apk.sh` | Igual que antes; se instala encima del piloto |

- Android: sabores en `android/app/build.gradle.kts`. Lo exclusivo de `directa`
  vive en `android/app/src/directa/`. `CanalesEdicion.kt` tiene una versión
  vacía para `play`.
- Dart: `edicionDirectaProvider` (`lib/core/plataforma/edicion.dart`) oculta el
  filtro, el tiempo por app, sus permisos y la sección de los informes.
- Legal 1.2.0: los textos de Play no mencionan el filtro, y se corrigió la frase
  sobre copias de seguridad, que era falsa con `allowBackup=false`. Al cambiar la
  versión, la app pide aceptar de nuevo.
- `docs/legal/*.md` describen la edición Play, que es la que se publica.

## Verificado

- `flutter analyze`: sin problemas.
- `flutter test`: todo verde salvo `tamano_test`, por `memoria_screen.dart` y
  `salud_screen.dart`, cambios sin commit de P0-6 ajenos a este trabajo.
- Compilan `assemblePlayDebug` y `assembleDirectaDebug`.
- Manifiesto fusionado de `playRelease`: sin VPN, uso, `FOREGROUND_SERVICE` ni
  `INTERNET`.
- `FiltroWebVpnService` no aparece en el dex de `play` y sí en el de `directa`.

## NO VERIFICADO

- AAB firmado: el keystore no es visible desde el sandbox de los agentes.
- Ninguna de las dos ediciones se ha ejecutado en emulador o teléfono.
- El código Dart del filtro sigue en el binario de `play`, sin ruta que lo abra.
- Revisión legal de los textos 1.2.0.
