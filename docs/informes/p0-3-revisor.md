# Informe — P0-3 (administrador de dispositivo) — 2026-11-08

Rama `feat/modular-freemium-aws`, base `c6ca23b`, cambios **sin commitear**.
Objetivo: retirar el `DeviceAdminReceiver` por la política de Play (opción A).

Veredicto: **CORRECCIONES** (0 bloqueantes, 0 graves, 3 menores, 2 sugerencias)

## Verificación ejecutada (no se confió en el informe del agente)

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | `No issues found!` (22,9 s) |
| `flutter test` | **380/380** |
| `flutter test test/arquitectura/manifiesto_test.dart test/padre/` | **164/164** |
| `aapt2 dump xmltree` sobre `build/app/outputs/flutter-apk/app-debug.apk` | Solo `FiltroWebVpnService` (control positivo); sin `ProteccionReceiver`, `BIND_DEVICE_ADMIN` ni `device_admin` |
| `unzip -l` sobre el APK debug | Sin recurso `device_admin` |
| `git diff --check` | Limpio |
| `pubspec.yaml` / `pubspec.lock` | Sin cambios |
| Texto de IA / `Co-Authored-By` en el diff | No aparece |
| `print()` / `TODO` / `FIXME` en lo tocado | No aparece |
| `git log c6ca23b..HEAD` | 0 commits: no hay mensaje que auditar; todo está en el árbol de trabajo |

El código de la retirada está completo: no quedan referencias en `lib/`, `test/`, `android/` ni en los textos de la app. El manifiesto fuente y el APK debug no declaran el administrador.

## BLOCKER (bloqueante)

- Ninguno.

## MAJOR (grave)

- Ninguno.

## MINOR (menor)

- [PROGRESO.md:77] La documentación interna sigue afirmando que falta `DeviceAdminReceiver` y que la desinstalación está bloqueada (`PROGRESO.md:78`, `:295`, `:330-338`, `:376`), mientras `docs/informes/p0-3-admin-fuera.md:108` da por cumplido que «la documentación interna deja de prometer el bloqueo». Añadir una nota de P0-3 como la de `docs/informes/3a-evidencia.md:9-14` o actualizar esas líneas a «descartado por P0-3; la app se desinstala como cualquier otra». Sin esto no se cumple el criterio de aceptación del módulo.

- [docs/informes/p0-3-admin-fuera.md:104-105] El criterio «no hay … en la edición Play» se marca `[x]` con evidencia de un APK **debug**; no se compiló release/AAB. El manifiesto fusionado de release en `build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml:132` (6-nov) y los APK release de `build/app/outputs/apk/release/` (22-oct) todavía contienen `ProteccionReceiver`/`BIND_DEVICE_ADMIN`; no sirven para validar P0-3. Acción: marcar release/AAB como **NO VERIFICADO** (el AAB está bloqueado por P0-1) o recompilar release/AAB y verificar el manifiesto fusionado antes de cerrar el módulo.

- [test/arquitectura/manifiesto_test.dart:9-16] El test de regresión solo lee `android/app/src/main/AndroidManifest.xml`. Un manifiesto de otro source set (`debug`, `profile`, `release`) o un receptor inyectado por una dependencia en el manifiesto fusionado no haría fallar el test; además no hay control positivo (si el manifiesto se vaciara, las tres aserciones pasarían). Acción: recorrer todos los `android/app/src/**/AndroidManifest.xml`, añadir una aserción positiva (`FiltroWebVpnService` o `<application`) y, para cubrir «por otra vía», un chequeo del manifiesto fusionado/AAB en el script de build. Las aserciones por subcadena también fallarían ante un comentario legítimo que mencione `device_admin`; parsear el XML sería más preciso.

## SUGERENCIA

- [docs/informes/3a-evidencia.md:152-157] El bullet de NO VERIFICADO sobre la fricción del `DeviceAdminReceiver` describe un componente que ya no existe. El banner de `docs/informes/3a-evidencia.md:9-14` lo contextualiza, pero conviene marcarlo «(ya no aplica: retirado en P0-3)» para que no se lea como estado actual.

- [docs/informes/p0-3-admin-fuera.md:33-35] `ProfileInstallReceiver` no está en el manifiesto fuente: entra por AndroidX en el manifiesto fusionado. La frase «los otros receptores del manifiesto» puede confundir a quien abra `AndroidManifest.xml` y solo vea dos; aclarar «manifiesto fusionado».

## Commits

No hay commits en la entrega (`c6ca23b..HEAD` vacío), así que no se puede auditar mensaje, granularidad ni texto de IA. Al commitear, usar un `FIX:` coherente (p. ej. `FIX: retira el administrador de dispositivo por Play`) y no mezclar con otros cambios.

Untracked del módulo que deben entrar en el commit: `test/arquitectura/manifiesto_test.dart` y `docs/informes/p0-3-admin-fuera.md`. No mezclar las capturas `docs/informes/capturas/3b-*.png` ni `requisitosPlayStore.md`, que no son de P0-3.
