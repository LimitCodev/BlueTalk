# Fase 0 — notas de ejecución (plan 10)

## 2026-10-14 — Desviaciones y hallazgos durante la ejecución

### Agentes de la Ola 2 sobrevivieron al reinicio (trabajo en paralelo no previsto por el plan)
Al ejecutar la Fase 0 comprobé que los subagentes `modo-padre` (y posiblemente
`rutinas-salud`) siguen vivos: crean/editan `test/padre/*.dart` en caliente
(mtimes posteriores al inicio de esta sesión) y corren `flutter test`.

Consecuencia: `flutter analyze` **global** muestra issues transitorios del WIP de
esos agentes (13 en `test/padre/` en el momento de escribir esto) ajenos a mis pasos.

**Desviación aplicada (mínima y documentada):** en los pasos 2–4 ejecuto gates
**acotados a mis rutas** (`flutter analyze <mis rutas>` → 0 + `flutter test test/data/`)
en vez del global, porque el global no puede estar en verde mientras otro agente
escribe. El gate global completo se ejecuta y documenta en el Paso 9, cuando los
agentes estén terminados. El plan 10 ya autoriza gates acotados en los pasos 2–4
("ejecuta solo flutter analyze y los tests del área tocada").

### Paso 1 — commits temáticos
- `e24dfda` `FEAT: modo padre…`: la ruta `test/padre` NO existía aún (la creó el
  agente vivo después); se añadirá con el Paso 6.
- `cfbaf1a` `FEAT: rutinas, salud y entorno`.
- `cd383ad` `DOCS: auditoria general y plan de fase 0`.

### Paso 2 — horario persistente
- Commit `635f578`. Bug propio en el test de escritura (usaba `entries.first`
  con la lista ya ordenada por hora: `escuela` era el primero, no la seed);
  corregido con `firstWhere` por id antes de commitear.

### Paso 3 — eventos de uso
- Commit `f41e982`. El test existente `seeds_test.dart` afirmaba la política
  antigua ("recorta a 200"): se actualizó a la nueva política (300 toques) en
  lugar de eliminarse; la cobertura nueva está en `test/data/usage_repo_test.dart`.

### Paso 4 — pantallas conectadas al router
- Commit `e6b2dd2`. Gates acotados: `flutter analyze` global marcaba 13+ issues
  del WIP en caliente de los agentes (todos en `test/padre/` y `test/rutinas/`);
  mis rutas con 0 issues y `flutter test test/core/` 41/41 verdes.
- El plan listaba import de `control_parental.dart` en `router.dart`: no hace
  falta (el guard `JuegosGate` ya lo importa dentro de su archivo). No se añadió
  import sin uso.
- Paso 4.7 (enlaces legales de Ajustes): se deja como está (apertura de diálogo),
  tal como autoriza el plan; los textos legales se ven desde Modo padre → Legal.

### Paso 8 — onboarding sin apodo: SIN CAMBIOS (premisa del plan incorrecta)
- La auditoría afirma "no permite empezar sin apodo"; el código real ya lo
  permite con el botón dedicado `Entrar sin apodo` (`onboarding_screen.dart:114`,
  siempre habilitado) y existe el test `router_test.dart`
  "el apodo es opcional: se puede entrar sin él", **en verde en esta sesión**
  (incluido en el `test/core/` 41/41 ejecutado para el Paso 4).
- Habilitar `Comenzar` con texto vacío crearía DOS botones con la misma acción
  (peor para lenguaje literal infantil). Se respeta la cláusula "detente y
  anota" del plan: verificado, sin cambio, sin commit.

### Paso 5 — tests de rutinas (C5): EJECUTADO Y CERRADO POR EL AGENTE `rutinas-salud`, VERIFICADO POR MÍ
- Commits del agente: `e91971d` `FIX: arreglar tests de rutinas y su accesibilidad`
  (7 archivos, todos en `lib/features/{rutinas,salud,entorno}` y `test/rutinas/`)
  y `78fd977` `DOCS: informe de rutinas salud y entorno`
  (`docs/informes/rutinas-salud.md`, 105 líneas — leído, honesto y con salida real).
  **Desviación de forma:** el plan prescribe `TEST: corregir tests de rutinas y
  repetir menos Mi día`; el agente paralelo ejecutó el paso con su propio mensaje
  `FIX:` (español, ≤70, sin texto de IA). No se reescribe historia: el contenido
  commiteado es el que pide el paso.
- Criterio "renombra `SectionHeader('Mi día')` → `Resumen de hoy`": verificado
  con grep → **0** `SectionHeader('Mi día')` en `lib/`; `Mi día` queda SOLO en la
  tarjeta (`rutinas_screen.dart:82`) y en la cabecera de salud
  (`salud_screen.dart:72`), como exige el plan.
- Los 2 casos no diagnosticados se arreglaron **EN LA APP** (regla 4 del plan,
  no en el test): `actividad_tile.dart` — el SnackBar calculaba con el estado
  viejo `hecha` en vez del `nuevoEstado`, y `PictoMini` no tenía etiqueta
  semántica; `editor_horario_view.dart` — no recalculaba (`horarioProvider`) antes
  de leer el repositorio, por eso `Actividades quitadas` no aparecía.
- Gates ejecutados por mí tras el commit: `flutter analyze` global **0 issues**
  (¡ya ni el WIP de `test/padre` marca!), `flutter test test/rutinas` **31/31**,
  `flutter test test/core` **41/41**.
- **Desviación de alcance:** el plan exige "al terminar: `flutter test` completo
  en verde"; hoy `test/padre/` (creado por el agente ANTES del Paso 6) tiene
  rojos. La suite completa queda ligada al Paso 6 y se verifica en el Paso 9.

### Paso 6 — tests del modo padre: CERRADO (commit `7e54b88`)
- El agente `modo-padre` (cancelado por el coordinador el 14/10 a las 11:20)
  dejó 10 suites en `test/padre/` sin commitear; las verifiqué, corregí y
  cerré yo. Commiteado como prescribe el plan:
  `TEST: pruebas de PIN, limites y navegacion del modo padre` (13 archivos,
  +1470): las 10 suites + 3 arreglos de app que los tests obligaron (regla 4).
- **Causa raíz de los colgones ("did not complete")**: la PBKDF2 de
  `cryptography` cede con timers; en un cuerpo `testWidgets` (FakeAsync) un
  `await crearPinDePrueba(...)` sin pumps concurrentes es un deadlock — todos
  los tests que arrancaban con ese await colgaban para siempre. Arreglo:
  `harness.dart` siembra una huella **precalculada** para '1234' (sin hashing
  en tests; el par sal+huella se verificó con `verificar('1234') == correcto`).
- **Segunda causa**: `gate_controller.dart` — el `Timer.periodic` de la
  cuenta atrás notificaba un estado nuevo cada segundo aunque el reloj de
  prueba no avanzara → `pumpAndSettle` jamás asienta. Arreglo (inocuo en
  producción, ahorra rebuilds): si los segundos no cambiaron, el tick no
  toca el estado.
- **Tercer arreglo (bug real de la app)**: la huella fallida no mostraba
  ningún aviso (`mensaje: state.mensaje` = null); ahora enseña el literal
  del plan: «No se pudo comprobar. Escribe tu PIN.»
- **Cuarto (app)**: '1 de 2' se pintaba dos veces en Salud del padre
  (fila de métrica + detalle de la barra); el detalle pasa a nulo (la
  semántica de la barra sigue diciendo «… por ciento»).
- **legal_screen.dart**: el banner de aceptación pasa arriba del
  `ListView` (antes quedaba bajo el pliegue); revisado y conservado.
- **Borrado**: `test/padre/diagnostico_test.dart` — andamio de debugging
  del agente con error de compilación (interpolación de un `void`), no era
  una prueba.
- `control_test.dart`: fila legal bajo el pliegue → `scrollUntilVisible`
  **al final** del test (si se hace antes, el `ListView` perezoso desmonta
  los switches de arriba y el tap falla).
- Gates (ejecutados por mí): `flutter analyze` global **0 issues**,
  `flutter test` global **186/186 en verde** (17 s).

### Revisor de la ola 2 — disposición de los hallazgos

Informe: `docs/informes/ola2-comunicador-juegos.md` (commiteado en `bdb2c4e`).
Veredicto: CORRECCIONES en ambas entregas, **0 BLOCKER, 4 MAJOR, 6 MINOR**.
Disposición (coordinador):

- **MAJOR aac #2 (JSON corrupto rompe «Mis mensajes»)** — CORREGIDO YA en
  `dee3407`: `saved_messages.dart` envuelve la decodificación en `try`
  (`FormatException` + `TypeError`, ampliando el patrón del artista) y
  devuelve lista vacía; 4 tests nuevos en `saved_messages_test.dart`
  (analyze 0 + comunicador 23/23).
- **MAJOR aac #3 (commits fuera de carpetas dueñas)** — EXCEPCIÓN
  REGISTRADA aquí, como pide el informe (para que no escale a BLOCKER en la
  re-verificación final): los commits `78f538f`, `c02414c`, `cd16308`,
  `801e9d3` tocaron rutas ajenas (`lib/app/**`, `test/core/**`,
  `assets/pictos/muestra/**`, `pubspec.yaml`) **por petición del coordinador**
  (cableado router/shell + excepción `http` ya documentada en el propio
  informe §Notas de alcance); el revisor verificó **sin contaminación** con
  las carpetas WIP de la Fase 0. Registrada la excepción: cerrado.
- **MAJOR aac #1 (alturas fijas vs textScaler 1.6)** y **MAJOR juegos #1
  (galería del artista sin tope de bytes + `catch` estrecho)** — a la COLA
  obligatoria de la Fase 1 (plan 11): el primero afecta solo a escalas de
  letra grandes (la rejilla recorta con «…» a partir de ~1,12) y el segundo
  solo con galerías grandes; ninguno bloquea el APK de prueba. Ver
  `ola2-comunicador-juegos.md` MAJOR #1 de cada sección para el detalle con
  `archivo:línea`.
- **6 MINOR** — anotados en el informe; los de a11y de rutas y debounce de
  escrituras entran en los lotes de Fase 1 (§1 lints/perfilado y §? según
  el plan 11).
- Pregunta de producto elevada por el revisor (comportamiento del botón
  Atrás en `/home/aprender`): escrita en
  `docs/informes/decisiones-pendientes.md`; se conserva el comportamiento
  por defecto mientras el usuario no responda.
