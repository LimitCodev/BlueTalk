# Plan 05 — `modo-padre` (Ola 2, paralelo, esfuerzo L)

**Depende de:** `base-flutter` (Ola 1 terminada).
**Rutas dueñas:** `lib/features/padre/**`, `docs/legal/**`, `test/padre/**`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

La zona de adultos: gate seguro, control parental, dashboard con diagnóstico/sugerencias **sobre data mock claramente etiquetada**, enfoque de salud adulto, y el legal completo. Aquí se concentran los requisitos de **seguridad**.

## Alcance detallado

1. **Gate de acceso** (`gate/`)
   - Configuración inicial: crear PIN de 4 dígitos (hasheado con `cryptography`, salt persistido — **nunca** en claro) + desbloqueo biométrico opcional (`local_auth`).
   - Lockout progresivo: 5 intentos fallidos → 60 s de espera (acumulativo, persistido).
   - Como la web tenía "Código incorrecto, inténtalo de nuevo." — mismo flujo, pero seguro.
   - **Commits ejemplo:** `FIX: login seguridad por medio de la libreria cryptography`.

2. **Dashboard del padre** (`dashboard/`)
   - Métricas de data mock (semillas etiquetadas `isDemo: true`): uso por categoría, avance en juegos, horario cumplido, check-ins emocionales, tendencia semanal (barras nativas).
   - Banner visible: **"Datos de demostración"** hasta que exista sync real con Supabase.

3. **Diagnóstico y sugerencias** (`diagnostico/`) — *"diagnóstico en el modo padre/posibles sugerencias con data real"*:
   - MVP: motor de **reglas deterministas** sobre las métricas locales (ej.: "usa pocas categorías de comunicación → sugiere ofrecer pictos de intereses nuevos").
   - Reglas definidas en `assets/seed/observation_rules.json` (ya cargado en Ola 1) → output = "Observaciones" con severidad (info/atención).
   - **Disclaimer obligatorio:** "Orientativa, no es diagnóstico clínico. No sustituye a un profesional."
   - Diseño pensado para enchufar data real (Supabase) después sin tocar el motor (contrato `UsageRepo`/`ObservationRule`).

4. **Control parental** (`control/`)
   - Límite de tiempo diario en juegos (drift + aviso al agotarse, corte suave sin pantallazo rojo).
   - Bloqueo/desbloqueo de secciones (juegos, entorno).
   - Sonido, Modo calma forzado, tamaño de texto (enlaces a Ajustes, sin duplicar lógica).

5. **Enfoque de salud (vista padre)** (`salud_padre/`)
   - Resumen de check-ins/hábitos del niño + historial semanal.
   - **Disclaimer de salud** (idéntico al plan 04).

6. **Legal** (`docs/legal/` + pantalla en app)
   - `TERMINOS_Y_CONDICIONES.md` → render en app con scroll, aceptación registrada (fecha + versión), rechazo impide entrar al modo padre.
   - `PRIVACIDAD.md`: qué datos se guardan (locales), Supabase futuro, derechos del usuario, contacto demo, sin datos reales.
   - Consentimiento parental explícito (checkbox) — necesario para futura publicación en Play (familias).
   - Texto redactado, preciso, sin muletillas de IA; extenso y detallado como pidió el usuario.

## Fuera de alcance

Auth real de Supabase (plan 06), pagos/Premium, notificaciones push remotas.

## Commits previstos (ejemplos)

```
FEAT: gate de modo padre con pin hasheado y lockout
FIX: login seguridad por medio de la libreria cryptography
FEAT: dashboard con metricas de uso etiquetadas como demo
FEAT: motor de observaciones con reglas y disclaimer
FEAT: limite de tiempo diario en juegos con aviso suave
FEAT: bloqueo de secciones desde control parental
DOCS: terminos y condiciones de uso detallados
DOCS: politica de privacidad y consentimiento parental
TEST: pin incorrecto cinco veces activa lockout
TEST: hash de pin nunca se persiste en claro
```

## Criterios de aceptación

- [ ] PIN solo como hash + salt; lockout probado por test.
- [ ] Dashboard visible con banner "Datos de demostración".
- [ ] Observaciones generadas por reglas + disclaimer de no diagnóstico.
- [ ] T&C y privacidad renderizados, aceptación versionada y persistida.
- [ ] Cero datos reales (grep antes de commit).
- [ ] `flutter analyze` 0 issues; tests de gate/dashboard en verde.
