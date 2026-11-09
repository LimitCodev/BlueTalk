# P0-3 — Administrador de dispositivo fuera de la app (2026-11-08)

Rama `feat/modular-freemium-aws`. Base `c6ca23b`.

## Qué se corrigió

`requisitosPlayStore.md` marca como **P0-3** el `DeviceAdminReceiver` que
solo servía para que desinstalar BlueTalk exigiera desactivar antes el
administrador. La política de malware de Play lo prohíbe con esas palabras:

> "Don't use device admin features to block uninstallation. Provide a clear
> and easy way for users to remove your app."

El dueño eligió la **opción A: quitarlo** (registro en
`docs/informes/decisiones-pendientes.md`). Se acepta que la app se
desinstale como cualquier otra; el PIN sigue protegiendo el panel del
adulto, no la desinstalación.

## Alcance retirado

| Antes | Después |
|---|---|
| `<receiver .ProteccionReceiver>` con `BIND_DEVICE_ADMIN` en el manifiesto | Sin receptor ni permiso |
| `ProteccionChannel.kt` (112 líneas) y canal `bluetalk/proteccion` | Eliminados |
| `res/xml/device_admin.xml` | Eliminado |
| `lib/features/padre/proteccion/` (controlador, gateway y tile) | Eliminado |
| `ProteccionTile` en Control › Permisos del teléfono | Fila eliminada |
| Entrada «Administrador del dispositivo» en el asistente de permisos | Eliminada |
| `PermisoId.administrador` | Eliminado del enum |
| `test/padre/proteccion_test.dart` (132 líneas) | Eliminado |
| Textos que prometían bloquear la desinstalación | Corregidos en `docs/play/permisos.md` y en la evidencia 3a |

No se tocaron los otros receptores del **manifiesto fusionado**:
`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver` y
`ProfileInstallReceiver` (notificaciones locales y perfil de AndroidX; los
dos primeros sí están en el manifiesto fuente, el tercero lo inyecta
AndroidX al fusionar).

## Archivos tocados

- `android/app/src/main/AndroidManifest.xml` — fuera el receptor y su
  `meta-data`.
- `android/app/src/main/kotlin/com/limitcodev/bluetalk/MainActivity.kt` —
  fuera el registro y la liberación de `ProteccionChannel`.
- `android/app/src/main/kotlin/com/limitcodev/bluetalk/ProteccionChannel.kt`
  — eliminado.
- `android/app/src/main/res/xml/device_admin.xml` — eliminado.
- `lib/features/padre/proteccion/` — eliminados `proteccion_controller.dart`,
  `proteccion_gateway.dart` y `proteccion_tile.dart`.
- `lib/features/padre/control/control_screen.dart` — sin `ProteccionTile`.
- `lib/features/padre/permisos/permiso_model.dart` — sin
  `PermisoId.administrador`.
- `lib/features/padre/permisos/permisos_controller.dart` — diagnóstico de
  cuatro permisos en paralelo, sin el administrador.
- `lib/features/padre/permisos/permisos_asistente_screen.dart` — sin el caso
  `administrador`.
- `lib/features/padre/permisos/permisos_gateway.dart` — comentario alineado.
- `test/padre/permisos_test.dart` — se quitaron las dobles del administrador;
  el caso de «solo un permiso opcional pendiente» usa ahora batería.
- `test/padre/proteccion_test.dart` — eliminado.
- `test/arquitectura/manifiesto_test.dart` — **nuevo**, tres pruebas de
  regresión.
- `docs/play/permisos.md`, `docs/informes/3a-evidencia.md`,
  `docs/informes/decisiones-pendientes.md`,
  `docs/informes/informes-optimizacion-estado.md` y
  `docs/informes/p0-4-permisos-opcionales.md` — notas de actualización.

## Pruebas de regresión

`test/arquitectura/manifiesto_test.dart`:

1. Recorre **todos** los `android/app/src/**/AndroidManifest.xml` (main,
   debug y profile) y ninguno contiene `BIND_DEVICE_ADMIN`,
   `ProteccionReceiver` ni `device_admin`.
2. Control positivo: el manifiesto principal conserva `<application` y
   `FiltroWebVpnService`, para que el test no pase en vacío si el archivo
   desapareciera.
3. `MainActivity.kt` no menciona `ProteccionChannel`, y ya no existen
   `ProteccionChannel.kt` ni `res/xml/device_admin.xml`.

Así, si alguien vuelve a añadir el administrador por descuido, la suite
falla antes del commit. El manifiesto **fusionado** de release no lo cubre
este test: lo valida el build de release/AAB (pendiente por P0-1).

## Verificación

| Comando | Resultado |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` | **381/381** |
| `flutter test test/arquitectura/manifiesto_test.dart test/padre/` | **165/165** |
| `flutter build apk --debug` | Correcto; APK de 212.054.298 bytes |
| `aapt2 dump xmltree` sobre el APK | Sin rastro del administrador |

Salida relevante de `aapt2` (build-tools 36.0.0) sobre
`build/app/outputs/flutter-apk/app-debug.apk`:

```text
$ aapt2 dump xmltree --file AndroidManifest.xml app-debug.apk \
    | grep -E 'ProteccionReceiver|BIND_DEVICE_ADMIN|device_admin|FiltroWebVpnService'
            A: android:name="com.limitcodev.bluetalk.FiltroWebVpnService"
```

Solo aparece el control positivo (el servicio VPN del filtro web); no hay
coincidencias de `ProteccionReceiver`, `BIND_DEVICE_ADMIN` ni
`device_admin`. Los tres receptores que quedan son los de notificaciones
locales y el de AndroidX Profile Installer.

## Revisión independiente

El subagente `revisor` revisó el módulo (`docs/informes/p0-3-revisor.md`):
**0 bloqueantes, 0 graves, 3 menores y 2 sugerencias**. Se corrigieron los
tres menores y las dos sugerencias:

1. `PROGRESO.md` ya no presenta el administrador como pendiente: lleva una
   nota de P0-3, la fila 3.1 queda como «descartado» y la sección 3a.2 está
   marcada como histórica.
2. La evidencia separa lo verificado (fuente y APK debug) de lo **NO
   VERIFICADO** (manifiesto fusionado de release y AAB, bloqueados por
   P0-1); avisa de que los APK release antiguos no validan el cambio.
3. El test de regresión recorre los tres manifiestos fuente y añade un
   control positivo en el manifiesto principal.
4. Se marcó como histórica la fricción de desinstalación en
   `docs/informes/3a-evidencia.md`.
5. Se aclaró que `ProfileInstallReceiver` viene del manifiesto fusionado.

## Criterios de aceptación del documento

- [x] El código fuente y el APK **debug** no declaran
  `BIND_DEVICE_ADMIN`, `DeviceAdminReceiver` ni `device_admin.xml`.
- [ ] El manifiesto fusionado de **release** y el AAB: **NO VERIFICADO**.
  El AAB sigue bloqueado por P0-1 (keystore ausente); los APK release que
  había en `build/` son anteriores a P0-3 y no validan este cambio.
- [x] La documentación interna deja de prometer el bloqueo (notas en
  `PROGRESO.md`, `docs/informes/3a-evidencia.md` y `docs/play/permisos.md`).
- [ ] Prueba en teléfono físico (instalar, comprobar que no pide
  administrador y desinstalar): **NO VERIFICADA** en esta sesión.

## Lo que sigue en `requisitosPlayStore.md`

- **P0-2 VPN**: depende de que el dueño elija ruta A (quitarla de Play) o
  B (rediseñarla con DoH).
- **P0-1 keystore**, **P0-5 identidad/correo/URL** y **P0-8 cuenta y
  testers**: decisiones del dueño.
- **P0-6 ficha y assets**: pendiente de empezar.
