# Informe — rutinas-salud-entorno — 2026-10-14

Veredicto (auto-revisión): APROBADO PARA REVISIÓN DEL REVISOR

Alcance entregado: `lib/features/{rutinas,salud,entorno}/**`, `test/rutinas/**`.
No se tocó ningún archivo fuera de las rutas dueñas (verificado con
`git log --stat` por commit y `git status --short`).

## Qué se implementó (por commit)

1. `cfbaf1a` — `FEAT: rutinas, salud y entorno` (Ola 2 completa)
   - Horario del niño con banner "Siguiente actividad", lista por hora
     con picto y marca hecha/pendiente (toca = alterna, feedback suave
     con SnackBar reversible). El estado "hecha" vive en eventos de uso
     (`actividad_hecha` / `actividad_pendiente` en `UsageRepo`, el
     último evento del día manda) para no ensuciar los hábitos que lee
     el dashboard del padre.
   - Editor de horario (persona adulta): alta, edición, quitar
     (`enabled: false`; el contrato no tiene delete) con sección
     "Actividades quitadas" y Restaurar.
   - Bienestar (`salud_screen.dart`): check-in emocional (5 moods del
     semilla, id fechado `mood_<ms>`), hábitos diarios con pictos (ids
     fechados `hab_<id>_<yyyy-mm-dd>`), Modo calma y velocidad de voz
     reutilizando la lógica de Ajustes. Disclaimer visible en la
     cabecera: "Esta app no reemplaza evaluación profesional. Consulta
     a tu especialista." (`salud_screen.dart:14`).
   - Entorno/colegio 100% ficticio: "Colegio Demostración Norte",
     contacto `demo@bluetalk.app` ("Coordinadora: Sra. Ejemplo"),
     banda "Datos de demostración" y guía de llegada con pictos.
   - Estadísticas básicas sin librerías de gráficas: uso por día (7),
     check-ins de la semana, hechas de hoy.
   - Persistencia vía contratos de Ola 1 (`ScheduleRepo`,
     `WellbeingRepo`, `UsageRepo`); `lib/data/` no se tocó.

2. `e91971d` — `FIX: arreglar tests de rutinas y su accesibilidad`
   (Paso 5 del plan 10; corrige los 11 tests rojos de `test/rutinas/`)
   - Bug real de la app: el SnackBar mostraba el estado **anterior** a
     alternar (`actividad_tile.dart`) — al marcar "Recreo" como hecha
     decía "pendiente otra vez". Arreglado en la app, no en el test.
   - Bug real: `quitadasProvider` (`editor_horario_view.dart`)
     observaba `scheduleRepoProvider`, cuya identidad nunca cambia → la
     sección "Actividades quitadas" no aparecía tras quitar/restaurar.
     Ahora observa `horarioProvider` como señal de recálculo.
   - `'Mi día'` duplicado en el inicio (tarjeta + encabezados internos):
     los `SectionHeader` de `horario_view.dart` (DiaHoySection) y
     `estadisticas_view.dart` pasan a "Resumen de hoy"; `Mi día` queda
     solo en la tarjeta de inicio y la cabecera de Bienestar.
   - Accesibilidad: `PictoMini` acepta `semanticsLabel` (las imágenes
     SVG sin etiqueta eran 3 hallazgos del gate en la guía de entorno)
     y el `Checkbox` de hábitos va envuelto en `Semantics(label:)` (4
     hallazgos en Bienestar).
   - Test "el modo calma": el `SwitchListTile` queda bajo el pliegue
     del `ListView`; se desplaza con `scrollUntilVisible` antes de
     tocar.

## Verificación ejecutada (salida real)

- `flutter analyze lib/features/rutinas lib/features/salud lib/features/entorno test/rutinas`
  → `No issues found!`
- `flutter test test/rutinas` → `All tests passed!` (31 tests)
- `grep -rn "Laura\|Colegio San Miguel" lib/features/{rutinas,salud,entorno} test/rutinas`
  → 0 coincidencias.
- Gate de accesibilidad (`expectSinProblemasDeAccesibilidad`) verde en:
  sección de salud, editor de horario y estadísticas sin datos.

## NO VERIFICADO (declarado con honestidad)

- `flutter test` **completo** en verde: la suite global arrojó 4 fallos,
  todos en `test/padre/` (árbol sin commitear del agente de modo padre,
  en vuelo), y la corrida quedó interrumpida por un SIGTERM tras
  atascarse en `test/padre/gate_test.dart`. Ningún fallo de mis rutas;
  debe re-ejecutarse cuando `test/padre/` esté commiteado y en verde.
- Rendimiento en dispositivo físico y voz TTS real: fuera del alcance
  sin teléfono.

## Checklist plan 08 (aplicado a la entrega)

1. **Seguridad y datos** — BLOCKER descartado: cero datos reales
   (grep verificado), datos del colegio etiquetados como
   demostración, disclaimer de salud visible, sin PIN/claves en claro.
2. **Reglas del plan 00** — `pubspec.yaml` NO tocado; sin `git push`;
   commits en convención `TIPO: descripción en español`; solo rutas
   dueñas. NOTA: el commit del Paso 5 se tituló `FIX: …` en vez del
   `TEST: …` sugerido por el plan 10 porque incluye correcciones
   reales de la app (no solo tests); formato válido del plan 00 §6.
3. **Calidad de código** — analyze 0, tests verdes, listas con
   `ListView` perezoso, sin `print()`, sin trabajo pesado en `build()`.
4. **Accesibilidad/autismo** — gate verde, targets ≥48dp, lenguaje
   literal sin metáforas, ningún audio ni voz automática (la voz solo
   bajo toque), navegación interna fija (`RutinaVista`).
5. **Rendimiento gama baja** — sin dependencias nuevas; modo calma
   respetado (`disableAnimations` verificado en el harness de tests).

## Cableado pendiente para el coordinador

- El Paso 5 del plan 10 ya está cerrado (`e91971d`); quedan los pasos
  6–9 (test/padre, dependencias sin uso, onboarding, verificación
  final) que pertenecen a otros agentes.
- `RutinasScreen` ya está cableada en `/home/rutinas` y el bloqueo de
  "Mi colegio" con `bloqueosProvider` resuelto en el commit
  `e6b2dd2` del coordinador; no hice cambios de router.
- Al integrar: re-ejecutar `flutter test` completo tras commitear
  `test/padre/`.

Bloqueantes: ninguno.
