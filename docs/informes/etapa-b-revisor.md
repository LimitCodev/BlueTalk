# Etapa B — informe del revisor (2026-10-18)

Revisión con subagente `revisor` de los 7 commits (`5ef1cd3`…`c466072` más el cierre de etapa).
Veredicto: **CORRECCIONES** — ningún GRAVE; 2 MEDIO, 6 LEVE.
Ejecutó `flutter analyze` (0) y `flutter test` (247/247) en el árbol actual
(HEAD limpio en el momento de la revisión); revisó diffs commit a commit, `pubspec.yaml`
intacto desde la Ola 1, sin `git push`, mensajes en español ≤70
caracteres sin texto de IA, y verificó las capturas `etapa-b-03` y
`etapa-b-05` contra el código (coherentes: 6 opciones, Celeste marcada,
shell entero en durazno, pictogramas y logo con sus colores fijos).
Confirmado: el logo usa solo `Marca.*` (`logo_bluetalk.dart:49,66,83`),
el selector es ≥48 dp (`ajustes_screen.dart:542-582`), sin autoplay
añadido, el modo calma manda (`app.dart:45-47`), la persistencia del
tema tiene test (`ajustes_test.dart:41-61`) y el contraste AA de las 6
paletas usa la fórmula WCAG real (`tokens_test.dart:10-27`, verificada
a mano en durazno: texto/bg 10.8:1, ink/fill 6.9:1).

Pendiente de corrección (en este orden):

## MEDIO (commits `FIX:`)

1. **[MEDIO] `lib/core/theme/app_theme.dart:10-20`** —
   `ColorScheme.fromSeed(paleta.primary)` deja tonos derivados **fuera
   del test AA de las 6 paletas**: solo `primary/onPrimary/surface/
   onSurface/error` se fijan en el `copyWith`; `surfaceContainerHighest`,
   `outline` y `secondary` varían por paleta y los usa la UI real:
   `lib/features/juegos/artista/artista_screen.dart:274` (fondo del
   grosor inactivo), `SwitchListTile` en
   `lib/core/theme/calm_mode.dart:38`, `lib/features/ajustes/
   ajustes_screen.dart:137`, `lib/features/padre/control/
   control_screen.dart:38,79,88,117`, `Checkbox` en
   `lib/features/salud/salud_screen.dart:239`, borde de `OutlinedButton`
   en `lib/features/comunicador/phrase_bar.dart:68`. Caso límite real:
   `altoContraste` usa seed `#000000` (`app_colors.dart:96`), croma 0 →
   HCT deriva grises, así que en el tema «Alto contraste» interruptores,
   checkbox y bordes pueden quedar gris de bajo contraste, contradiciendo
   el nombre del tema. → fijar en `copyWith` los tonos que la UI usa
   (mínimo `surfaceContainerHighest`, `outline`, `secondary`) desde
   tokens por paleta, o extender `tokens_test.dart` al `colorScheme`
   resultante de cada paleta con los usos citados.
2. **[MEDIO] `android/app/src/main/AndroidManifest.xml:7` (commit
   `813ff18`, ya rehacho como `de7e47a`)** — El cambio de identidad `android:label` «bluetalk» →
   «BlueTalk» (cambio de producto, visible en el launcher) quedó dentro
   de un commit `DOCS:` de evidencia y capturas. El mensaje lo menciona,
   pero §6 exige 1 commit = 1 cambio coherente: un `FIX:`/`CHORE:`
   propio (como el de Etapa A con `c3238d4`) deja rastro limpio de
   cuándo cambió la identidad. → para próximas entregas separar; aquí,
   anotar que el label cambió en `813ff18` y se rehizo bien en `de7e47a`.

## LEVE (un `DOCS:` de corrección del informe)

3. `lib/core/theme/app_colors.dart:8` — el doc dice verificado por
   «`test/core/tema_test.dart`»: ese archivo no existe (el real es
   `test/core/tokens_test.dart`). Idem `lib/core/widgets/
   section_header.dart:7-8`: la migración dejó `[context.colores.primary]`
   como referencia dartdoc inválida.
4. `docs/informes/etapa-b-evidencia.md:12-18` — la tabla de estado salta
   P3.3 («Guarda el logo en `assets/brand/`, declara el asset»). Se
   resolvió bien con `CustomPainter` y sin tocar `pubspec.yaml` (el plan
   permite «mejor SVG si se recrea con CustomPainter»), pero la fila
   debe existir como «P3.3 — no aplica (CustomPainter, sin asset)» para
   que la tabla cubra todos los pasos.
5. `test/features/ajustes_test.dart:124-151` — la vista previa en vivo
   no tiene test automatizado: el test usa un `MaterialApp` plano, así
   que nada prueba que `lib/app/app.dart:25-30` repinte toda la app con
   la paleta elegida; la afirmación se apoya solo en las capturas
   manuales (coherentes, pero manuales). → test de `BlueTalkApp` con
   `tema: 'durazno'` que compruebe el `scaffoldBackgroundColor`.
6. `docs/informes/etapa-b-evidencia.md:28,119` — `colores.py` y
   `gen_icon.py` (los generadores de la paleta y del ícono) no están en
   el repo ni sobreviven en `/tmp`: la extracción de colores y los
   PNGs heredados no son reproducibles desde el repo (sí los outputs
   commiteados). → commitearlos en `scripts/` o declarar «script de una
   vez, no versionado» en el informe.
7. `lib/features/ajustes/settings_controller.dart:30` + `lib/data/
   models/app_settings.dart:29` — `setTema` no valida la id (un valor
   corrupto editando SharedPreferences a mano rompería el `as String?`
   y dejaría Ajustes en estado de error); una id desconocida cae a
   celeste en `app.dart:26` pero el selector queda **sin ninguna opción
   marcada** (`ajustes_screen.dart:497`). → normalizar id desconocida a
   `'celeste'` al cargar.
8. `lib/features/onboarding/onboarding_screen.dart:8` — el doc comment
   dice «Tu voz, siempre contigo 💙» y el texto visible es 💚 (verde del
   cartel, `:78`). Además `5ef1cd3` (commit `FEAT:`) incluye la primera
   sección del informe de evidencia: mezcla DOCS+FEAT (§6; mencionar
   ambos en el cuerpo o separar en próximas entregas).

Nota (no nuevo): el correo personal del autor sigue en el historial de
estos commits; es el hallazgo 9 de `etapa-a-revisor.md`, ya en manos
del dueño.

Estado: todo commiteado (HEAD limpio), árbol limpio. Este informe
queda listo para commitear como `DOCS: informe del revisor de la etapa
B`. Tras corregir 1-2 (`FIX:`) y 3-8 (`DOCS:`), Etapa B puede cerrarse
y seguir con la Etapa C (plan 11).
