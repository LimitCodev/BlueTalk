# Etapa A — informe del revisor (2026-10-16)

Revisión con subagente `revisor` tras cerrar la etapa (commit `76d5d97`).
Veredicto: **CORRECCIONES** — ningún GRAVE; 3 MEDIO, 6 LEVE.
Ejecutó `flutter analyze` (0) y `flutter test` (234/234), revisó los 10
commits de la etapa (mensajes válidos, sin push, sin texto de IA),
contrastó tamaños de APK, permisos, contraste AA, ≥48 dp, sin autoplay,
y confirmó que «R8 ya venía activo por defecto» es cierto
(`FlutterPlugin.kt:216` de este SDK).

Pendiente de corrección (en este orden):

## MEDIO (commits `FIX:`)

1. **[MEDIO] `lib/features/padre/padre_screen.dart:80` (con `:57-67`)** —
   El `PopScope` del modo padre llama a `_salir()` desde *cualquier* vista:
   Atrás desde las pestañas Control/Salud/Legal sale a Ajustes **y cierra
   la sesión**, en vez de «vuelve al panel del padre» (fila 4 de P1). El
   test `test/core/router_test.dart:352-411` solo cubre subpantalla
   empujada y gate; `etapa-a-evidencia.md:30` declara las 5 filas sin
   matizar. → `irA(resumen)` al retroceder desde pestañas que no son el
   panel (test en rojo previo) **o** dejar escrita la interpretación.
2. **[MEDIO] `docs/play/instalar-apk.md:16` y `:31`** — El texto manda
   hashear `BlueTalk.apk`, pero `scripts/build-apk.sh` solo genera
   `app-arm64-v8a-release.apk` / `armeabi-v7a` / `x86_64` y **no renombra**;
   `sha256sum BlueTalk.apk` falla tal cual. → alinear nombres (script y
   doc).
3. **[MEDIO] `test/rutinas/editor_horario_test.dart:128` +
   `lib/features/rutinas/editor_horario_view.dart:224`** — El commit
   `c3238d4` junta dos correcciones de causa distinta (aviso al fallar
   guardado; crash de la lista `const` al ordenar) y el mensaje solo nombra
   la primera (§6: 1 commit = 1 cambio coherente). El informe lo reconoce
   pero el cuerpo del commit no → mención en cuerpo o separar en próximas
   entregas.

## LEVE (un `DOCS:` de corrección del informe)

4. `etapa-a-evidencia.md:5` — «230 → 234 tests»: `estado-vivo.log` marca
   **222** al empezar → debe decir 222 → 234.
5. `etapa-a-evidencia.md:92` — «43 SVG (440 KB)»: son **42** `.svg`
   (344 KB en bytes); los 444 KB de `du` incluyen `LICENCIA-MULBERRY.txt`.
6. `etapa-a-evidencia.md:24-30` — P1 pedía migrar a rutas go_router **o
   explicar en el informe** por qué PopScope; falta la razón escrita
   (sin ruta no hay deep link ni estado en el back stack).
7. `etapa-a-evidencia.md:98` — Medidas en Android 28; P7.2 pide API 24 →
   añadir a NO VERIFICADO o medir en API 24.
8. `etapa-a-evidencia.md:33,46,123` — Capturas en `/tmp/opencode/`
   (efímeras): mover a `docs/informes/capturas/` (sitio que usa el plan).
9. Git metadata (preexistente, decisión del dueño): el correo personal
   `callirgos.josue2015@gmail.com` está en el historial, frente a §5.1
   «solo el nick LimitCodev» → anotar en `decisiones-pendientes.md`.

Estado al apagar la laptop 2026-10-16: todo commiteado (HEAD `76d5d97`),
árbol limpio, sin procesos en segundo plano. Reanudación: corregir 1–3
(`FIX:`), luego 4–8 (`DOCS:`), cerrar etapa (`ETAPA A CERRADA`) y pasar a
Etapa B (P3 logo + P4 colores).
