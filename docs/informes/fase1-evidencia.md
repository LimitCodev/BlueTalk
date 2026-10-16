# Fase 1 — evidencia de cierre (plan 11 §1.4)

Fecha: 2026-10-15. Equipo: AVD `bluetalk_gama_baja` (API 28 x86_64,
1024 MB, 2 núcleos, 720×1280) + host. Desviaciones y límites: ver
`fase1-notas.md`.

## Gates (última ejecución antes de cerrar)

- `flutter analyze`: **0 problemas** (`No issues found!`).
- `flutter test`: **221/221 en verde** (Fase 0: 190; +15 de
  recordatorios, +4 del artista, resto de la 1.2 ya contabilizados).
- `flutter build apk --release --split-per-abi` (firma debug de
  plantilla; el keystore definitivo es decisión del usuario):
  - `app-armeabi-v7a-release.apk`: **17,8 MB**
  - `app-arm64-v8a-release.apk`: **20,2 MB**
  - `app-x86_64-release.apk`: **21,7 MB**

## §1.1 Recordatorios — verificado en el AVD

Con el reloj del emulador adelantado a las 07:58 y «Entrada» a las 08:00:

1. **Programación exacta**: `adb shell dumpsys alarm` mostró alarmas
   `RTC_WAKEUP` de `com.limitcodev.bluetalk` con el receptor
   `ScheduledNotificationReceiver`; la primera con
   `when=1792155600000` = 08:00:00 (la actividad de las 08:00).
2. **Aviso entregado con la app en segundo plano**: tras pulsar Home,
   el aviso apareció en la lista de notificaciones con marca
   `13:00:00.119` UTC = **08:00:00.119 local** (119 ms de desviación
   con alarma inexacta).
3. **Texto literal del plan**: `dumpsys notification --noredact`
   mostró `android.title=String (Es hora de: Entrada.)`. Sin emojis.
4. **Canales**: `bluetalk_recordatorios` (con sonido y vibración) y
   `bluetalk_recordatorios_calma` (`mSound=null`,
   `mVibrationEnabled=false`).
5. **Sobrevive al reinicio**: tras `adb reboot`, sin abrir la app,
   `dumpsys alarm` volvió a mostrar las alarmas repuestas por
   `ScheduledNotificationBootReceiver` (la del aviso ya disparado no
   se repite, como corresponde).

Lógica de sincronización (crear/editar/quitar → reprogramar solo esa;
apagar → cancelar todos; encender → reprogramar; sin permiso → nada se
rompe; modo calma → reprograma en silencio): 11 tests en
`test/recordatorios/recordatorios_test.dart`. Interfaz de Ajustes
(explicación literal + permiso + denegación con aviso): 4 tests de
widget en `test/recordatorios/ajustes_recordatorios_test.dart`.

## §1.2 PIN y datos

- PIN de 6 dígitos con migración 4→6, PBKDF2-HMAC-SHA256 en
  `Isolate.run`, bloqueo escalonado (60/120/300/900 s con guard de
  reloj atrasado), recuperación borrando los datos y cambio de código:
  **56 tests** de `test/padre` en verde (incluyen casos de borde y
  almacenamiento corrupto).
- **§1.2.2 (iteraciones)**: medido en el AVD en modo perfil/AOT con
  `integration_test/pbkdf2_bench_test.dart`:
  10.000 = 58 ms · 25.000 = 212 ms · 50.000 = **301 ms** ·
  100.000 = 586 ms · 200.000 = 1.938 ms · 400.000 = 4.819 ms.
  100.000 no cumple el ≤500 ms del plan ⇒ se fijan **50.000
  iteraciones** (301 ms). Commit `PERF: pbkdf2 a 50000 iteraciones`.
- **§1.2.6**: `allowBackup=false`, `fullBackupContent=false` y
  `dataExtractionRules` con archivo sin reglas. El build de release
  compila con ellos integrados. El comportamiento del BackupManager no
  se ejecutó (ver NO VERIFICADOS).

## §1.3 Calidad y rendimiento medidos (AVD de gama baja, modo perfil)

| Métrica | Resultado | Tope del plan | Veredicto |
|---|---|---|---|
| Arranque en frío (`am start -W`, 5 tiradas) | 1054–2128 ms, mediana **1122 ms** | < 3 s | cumple |
| RAM en arranque (`dumpsys meminfo`, PSS TOTAL) | **85 MB** | < 150 MB | cumple |
| RAM tras uso (onboarding + rejilla + swipes) | **96 MB** | < 150 MB | cumple |
| Frames del scroll de la rejilla (`flutter drive --profile` + `traceAction`, eventos `Animator::BeginFrame`, 24 deslizamientos, 201 frames) | media 1,70 ms · p90 6,30 ms · p99 **9,46 ms** · máx 10,72 ms · **0 frames > 16,7 ms** | sin trabas | cumple; no se toca la grilla (§1.3.3) |

- §1.3.1 (lints estrictos): añadidas las 4 reglas que faltaban; analyze
  siguió en 0.
- §1.3.4: `ImageCache` limitado a 50 imágenes / 20 MB cuando el equipo
  tiene ≤ 3 GB de RAM (el AVD, con 1 GB, entra; lectura de `MemTotal`
  desde `/proc/meminfo` con lectura segura).
- §1.3.5: tope de **30 dibujos** y **3000 puntos por dibujo**; la
  galería llena rechaza guardar (sin borrado silencioso) y la pantalla
  pide literalmente borrar uno; fila corrupta ⇒ galería limpia sin
  romper. 4 tests nuevos en `test/juegos/artista_test.dart`.

## §1.2 / §1.3 — permisos y copias

`docs/play/permisos.md` justifica `RECEIVE_BOOT_COMPLETED` y
`POST_NOTIFICATIONS` y documenta los receptores y el bloqueo de copias.

## Commits de la fase (`git log 608be77..HEAD`)

```
1338b95 FIX: estado de error en seccion de recordatorios
5056655 FIX: endurece gate y borrado segun revision
67250f7 PERF: pbkdf2 a 50000 iteraciones (AVD: 301 ms)
365668e PERF: cache imagenes 50/20MB y perfilado con cifras en AVD
2e1b6fa FIX: limitar la galeria del artista
44fed13 CHORE: lints estrictos
bd53c09 FIX: desactivar copias de seguridad en la nube
ec9bac0 FEAT: permiso de notificaciones desde ajustes
df17581 FEAT: servicio de recordatorios locales
d89c255 FEAT: pin de 6 digitos, recuperacion y bloqueo escalonado
```

(más el commit `DOCS` de estos informes).

## Revisión del revisor y correcciones (§1.4)

El subagente `revisor` revisó `d89c255..67250f7`: **0 ALTA · 4 MEDIA ·
6 BAJA**, sin BLOCKER; re-ejecutó analyze, tests y release y cuadraron
con esta evidencia. Correcciones aplicadas y re-verificadas:

- `5056655` — las 4 MEDIA (tipo corrupto del PIN, guards tras `await`,
  doble toque en «Entrar», «Borrar todo» cancela avisos e invalida
  providers) + 2 BAJA (invalidar permisos, comentario de catch).
- `1338b95` — BAJA: estado de error visible en la sección
  «Recordatorios» con su test.

Gates tras las correcciones: `flutter analyze` **0 problemas** ·
`flutter test` **222/222** (la suite gana el test de doble-toque del
gate). Detalle de cada hallazgo y su resolución en
`fase1-notas.md` §"Revisión por el subagente revisor".

## NO VERIFICADO

Lista completa y motivo en `fase1-notas.md` §"NO VERIFICADO". Resumen:
permiso de avisos denegado en Android 13+ (AVD API 28), aviso con
pantalla apagada/Doze, biometría real, TTS real en español, comportamiento
ejecutado de `allowBackup` y cambio a canal de calma en vivo en el AVD.
Ninguno bloquea la fase; los que requieren teléfono físico pasan al
checklist de la Fase 3 (§3.9).
