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

### Pasos 5 y 6 en espera de los agentes de la Ola 2
- `rutinas-salud` y `modo-padre` siguen vivos (edits en caliente en
  `lib/features/rutinas/*.dart`, `test/rutinas/`, `test/padre/`) y trabajan
  exactamente en los contenidos de estos pasos (tests rojos de rutinas; tests de
  seguridad del padre). Tocar sus archivos ahora = conflicto directo.
- Plan: cuando terminen, verificar su salida contra los Pasos 5 y 6, completar
  lo que falte y commitear.
