# Etapa A — evidencia (CERRADA 2026-10-16)

Plan 13: P1 (Atrás), P2 (Artista), P6.1 (fallos de las reseñas) y P7
(instalación y APK liviano). Todos los pasos ejecutados, con `flutter
analyze` en 0 y la suite en verde (222 al empezar → **235 tests** al
cerrar) antes de cada commit. Sin `git push`.

## Estado por paso

| Paso | Estado | Commit |
|---|---|---|
| P1 — causa verificada en rojo (5 filas + gancho kiosko) | HECHO | `bb14fb3` FEAT, `c4d9257` TEST |
| P2 — Artista sin desplazamiento (2 tests rojos → fix) | HECHO | `cbed1b4` |
| P6.1-a — nombre con teclado abierto (test) | HECHO | `a20a985` |
| P6.1-b — rutinas avisa si guardar falla (rojo → fix) | HECHO | `c3238d4` |
| P6.1-c — la voz nunca suena sola (test) | HECHO | `a20a985` |
| P6.1-d — diagnóstico de voz «¿No se oye? Toca aquí» (rojo → fix) | HECHO | `d4088e2` |
| P7.1 — `docs/play/instalar-apk.md` + hash SHA-256 en build | HECHO | `6c92ef2`, `95ee0ce` |
| P7.2 — minify/shrink + humo en emulador + tamaños | HECHO | `cc7d5e6` |
| Informe + revisor de etapa | HECHO | este archivo |

## P1 — Atrás dentro de la app

- **Causa verificada en rojo** antes de tocar código: tests de las 5
  filas de la tabla del plan fallaban donde debían (rama Aprender no
  volvía al inicio, ramas secundarias salían de la app, kiosko sin
  gancho). Implementación: un único `PopScope(canPop: false)` en
  `AppShell` + `PopScope` en `PadreScreen` → `_salir()`, más
  `saleConAtrasProvider` (default true) como gancho del plan 12 F3.
- 6 tests en verde: 5 filas + fila kiosko.
- **Por qué `PopScope` y no rutas de `go_router`** (P1 permite elegir si
  migrar a rutas «es muy grande»): las vistas internas de Aprender y del
  modo padre están deliberadamente sin rutas — la navegación por estado
  desacopla el registro de sesiones (`juegosProvider` registra cada
  partida que alimenta el panel del padre) del router raíz. Migrarlas a
  rutas obligaría a rehacer ese registro y todos los tests de juegos; a
  cambio perdemos deep links y estado en el back stack, que para una app
  AAC de un solo niño con navegación fija no aporta nada. Decisión
  registrada aquí y en `00-PLAN-MAESTRO.md` §5.
- **Corrección tras la revisión** (`5ac4d4e`): el Atrás desde las
  pestañas Control/Salud/Legal del modo padre ahora vuelve al panel
  (Resumen) en vez de cerrar sesión; desde el panel o el gate sale a
  Ajustes; con la legal sin aceptar siempre se sale. Test rojo previo.
- **Verificado en emulador (release, APK real):** Aprender → Atrás →
  vuelve a **Comunicar** (la app no cerró); Comunicar → Atrás → sale al
  launcher (comportamiento normal de Android). Capturas en el historial
  de la sesión; NO VERIFICADO en el teléfono físico del dueño.

## P2 — Artista

- 2 tests rojos de aceptación (scroll vertical presente; «Borrar todo»
  inexistente) → lienzo en `Expanded` sin scroll, `Listener` con guard
  de puntero activo (ignora palma/segundo dedo), galería «Mis dibujos»
  en hoja inferior, «Borrar todo» con segundo toque («¿Seguro?»).
  12/12 en `artista_test.dart`.
- **Verificado en emulador:** dos swipes dentro del lienzo dibujan las
  dos trazas (la X aparece) y se activan «Guardar», «Deshacer» y
  «Borrar todo»; 0 excepciones fatales. El gesto **no** desplazó la
  pantalla. El «sentir» en pantalla táctil real sigue NO VERIFICADO.

## P6.1 — los cuatro puntos de las reseñas

1. **Nombre con teclado** (`a20a985`): test con
   `tester.view.viewInsets = const FakeViewPadding(bottom: 300)`: la
   pantalla no se congela, «Comenzar» se puede tocar y avanza al shell.
   Pasó directo (el `SingleChildScrollView` ya lo soportaba). Además
   **verificado en vivo** en el emulador: con el teclado ocupando media
   pantalla, «Comenzar» y «Entrar sin apodo» se veían y funcionaban.
2. **Rutinas** (`c3238d4`): antes `guardarActividad()` lanzaba y el
   error se perdía en silencio. Ahora `_guardar()` tiene try/catch con
   SnackBar literal «No se pudo guardar. Prueba otra vez.», sin cerrar
   el formulario y conservando lo escrito. Test con doble de
   `ScheduleRepo` que falla al escribir pero deja leer (lista con una
   actividad: con lista vacía no se construye la cabecera de edición).
   - **Hallazgo extra arreglado en el mismo commit:** el formulario
     ordenaba una lista `const` mientras `pictosPorIdProvider` estaba
     en `AsyncLoading` y crasheaba («Cannot modify an unmodifiable
     list»). Ahora la lista es mutable: con pictogramas cargando o en
     error muestra lista vacía y se rellena al llegar los datos.
3. **Voz** (`a20a985`): test «la voz nunca suena sola al abrir la
   app» (el `FakeTtsSpeaker.spoken` queda vacío tras arrancar en el
   shell). «Habla bajo toque» ya estaba cubierto desde la Ola 1.
4. **Diagnóstico de voz** (`d4088e2`): nueva pantalla
   `VozDiagnosticoScreen` accesible desde Control → «Pantalla y voz» →
   «Probar la voz», con botón ≥64 dp «¿No se oye? Toca aquí» que
   reproduce «Hola, soy BlueTalk» **solo bajo toque**; Atrás de la
   subpantalla vuelve al control. El test además deja constancia de
   que, al entrar, aún no se ha hablado.

## P7 — instalación y recursos

- **7.1** `docs/play/instalar-apk.md`: texto corto («Toca **Instalar
  de todas formas**…, no **Entendido**. La app no usa internet ni pide
  cuenta»), pasos, qué significa cada aviso y cómo comprobar el hash.
  `scripts/build-apk.sh` imprime tamaño y **SHA-256** de cada APK.
  Permisos ya justificados en `docs/play/permisos.md` y `INTERNET`
  ausente del manifiesto (comprobado). Lo de subir a prueba cerrada de
  Play Console queda como decisión del dueño (no hecho).
- **7.2** `--split-per-abi` (3 APKs), `isMinifyEnabled` +
  `isShrinkResources` explícitos en `build.gradle.kts`. Al verificar:
  **R8 ya venía activo por defecto** (AGP 9/Flutter): la inclusión de
  `minifyReleaseWithR8` en el grafo de tareas se comprobó con y sin el
  cambio; `shrinkResources` es lo nuevo, y no quita nada porque la app
  casi no tiene recursos propios → **el tamaño no cambia**: el peso es
  el engine de Flutter. Pictogramas = **42 SVG (344 KB)**: son
  vectoriales, mejor que WebP → no aplica (el único mapa de bits es el
  icono launcher, que se rediseña en Etapa B/P3 con el logo nuevo; en
  ese paso se decide su formato). Sin fuentes propias (solo la Roboto
  del engine) y `ListView.builder` ya en uso.

### Medidas (emulador AVD x86_64, Android 28, 1 GB RAM, APK de release)

| APK | Tamaño |
|---|---|
| `app-arm64-v8a-release.apk` (el del dueño) | 20,3 MB |
| `app-armeabi-v7a-release.apk` (móviles viejos) | 17,8 MB |
| `app-x86_64-release.apk` (emulador) | 21,7 MB |

- Arranque en frío (`am start -W`): **1521 ms**.
- Memoria (PSS total): **59,2 MB** en el shell infantil; **63,3 MB**
  con Artista abierto.
- Instalación firmada con el keystore de release: OK (hubo que
  desinstalar la copia debug previa del emulador por firma distinta).

## Desviaciones y anotaciones

- WebP no se aplica: los pictogramas son SVG (mejor solución que la
  que pide el plan); el icono launcher se verá en Etapa B/P3.
- `minifyEnabled` ya estaba por defecto; el commit solo hace explícito
  `shrinkResources` y documenta el porqué.
- El fallo de «Cannot modify an unmodifiable list» en el formulario de
  rutinas no lo pedía el plan: salió del test de P6.1-b y se arregló
  allí mismo (un fix por commit, pero mismo paso y misma causa de
  cobertura).
- El humo se hizo con `input tap/swipe/keyevent` de adb sobre emulador
  sin ventanas; las capturas que lo documentan quedan en
  `docs/informes/capturas/` (`arranque.png` = onboarding con teclado
  abierto, `shell.png` = shell infantil, `tras_atras.png` = Comunicar
  tras pulsar Atrás desde Aprender, `artista.png` = Artista con la
  galería de colores y `dibujo.png` = las dos trazas dibujadas).

## NO VERIFICADO (requiere teléfono físico o dato posterior)

- Atrás, dibujo y nombre-con-teclado **en el móvil del dueño** (en
  emulador y tests: verificados; la textura táctil real no).
- Voz TTS real (el emulador no tiene motor de voz), permisos
  `POST_NOTIFICATIONS`, recordatorios tras reiniciar (Doze/reinicio),
  biometría, `allowBackup` en el dispositivo.
- Memoria y arranque en el panel del padre (solo se midió el shell y
  Artista) y en el móvil real.
- Medidas en **Android 7 / API 24** (el perfil que pide P7.2 para
  móviles viejos): no hay AVD de API 24 en la máquina; el emulador
  disponible era Android 28. Las medidas y el humo de arriba son de
  API 28.
- APK final de la Fase 3 (con ícono nuevo y firma ya hecha falta
  recompilar tras P3/P4).

## Revisión del revisor y correcciones

`revisor` cerró la etapa con 0 GRAVE, 3 MEDIO y 6 LEVE (informe completo
en `etapa-a-revisor.md`). Correcciones aplicadas:

- MEDIO-1 (Atrás en pestañas del padre) → `5ac4d4e` con test rojo previo.
- MEDIO-2 (nombres de APK script vs doc) → `4f355b2`: el script genera
  `dist/BlueTalk.apk` (copia del arm64-v8a) y publica su SHA-256.
- MEDIO-3 (commit `c3238d4` con dos arreglos de causa distinta): no
  edita la historia; queda como lección escrita en `etapa-a-revisor.md`.
- LEVE 4–9 (cifras del informe, PopScope vs rutas, API 24, capturas en
  el repo, correo en el historial) → corregidos en este mismo cierre.

## Commits de la etapa

`bb14fb3` FEAT atras · `c4d9257` TEST atras · `cbed1b4` FEAT artista ·
`a20a985` TEST teclado/voz · `c3238d4` FEAT rutinas avisa ·
`d4088e2` FEAT diagnostico voz · `95ee0ce` FEAT script APK SHA-256 ·
`6c92ef2` DOCS instalar-apk · `cc7d5e6` PERF APK reduccion ·
`76d5d97` DOCS evidencia etapa · `bc35b31` DOCS informe revisor ·
`5ac4d4e` FIX atras pestanas padre · `4f355b2` FEAT dist/BlueTalk.apk

Siguiente: **Etapa B — P3 (marca y logo) y P4 (colores)**, según la
tabla de `AGENTS.md`.
