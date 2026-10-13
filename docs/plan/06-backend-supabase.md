# Plan 06 — `backend-supabase` (Ola 2, paralelo, esfuerzo M)

**Depende de:** `base-flutter` (Ola 1 terminada — contratos `lib/data/contracts/` ya definidos).
**Rutas dueñas:** `lib/data/remote/**`, `supabase/**`, `scripts/**`, `docs/backend/**`, `.github/workflows/keep-alive.yml`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

Montar Supabase free (decisión del usuario) con esquema, RLS y cliente Flutter **detrás del flag `USE_SUPABASE`**, sin romper el MVP offline y sin que la app dependa de la red.

## Contexto (investigación 2026)

- Supabase free: 500 MB, 2 proyectos, auth 50k MAU, **pausa a los 7 días sin tráfico** (restore manual 1 año).
- Mitigaciones obligatorias: workflow de keep-alive diario + dump manual (no hay backups automáticos en free).

## Alcance detallado

1. **Esquema SQL** (`supabase/migrations/0001_init.sql`)
   - Tablas: `profiles` (parent), `child_profiles`, `pictogram_usage`, `game_progress`, `schedule_entries`, `wellbeing_checkins`, `observations`, `settings_sync`.
   - Sin PII infantil: solo `display_name` opcional; todo ligado al `auth.uid()` del padre.
   - Índices en `created_at` y `child_id`.

2. **RLS estricta** (`0002_rls.sql`)
   - Cada fila filtrada por `auth.uid() = parent_id`. Sin acceso cruzado. Tests documentados de los escenarios (propio/ajeno).

3. **Seeds demo** (`supabase/seed.sql`)
   - Datos sintéticos con prefijo `[DEMO]`, mismas reglas del plan 05 (dashboard con data mock cuando `USE_SUPABASE=true`).

4. **Cliente Flutter** (`lib/data/remote/`)
   - `SupabaseClientFactory` (init con `--dart-define=SUPABASE_URL/SUPABASE_ANON_KEY`; claves **nunca** en el repo).
   - Implementaciones de los contratos de Ola 1 (`ProfileRepo`, `UsageRepo`, etc.) con estrategia: **lectura remota → caché local Drift → seed** (offline-first real).
   - Sync diferido: cola de escrituras pendientes en Drift, al recuperar red se suben (background, sin bloquear UI).

5. **Auth de padre** (`lib/data/remote/auth_repository.dart`)
   - Email+contraseña con Supabase Auth (futuro: magic link). El gate PIN local sigue siendo la barrera principal del MVP.

6. **Scripts** (`scripts/`)
   - `db_dump.sh`: `supabase db dump` programable (backup manual free tier).
   - `setup.sh`: pasos reproducibles de creación del proyecto (documentación en `docs/backend/SETUP.md`).

7. **Keep-alive** (`.github/workflows/keep-alive.yml`)
   - Cron diario que hace ping a la API para evitar la pausa de 7 días. Comentario en el workflow explica por qué existe.

8. **Flag por defecto OFF:** el MVP compila y corre sin red con datos locales; Supabase es opt-in.

## Fuera de alcance

Edge functions, storage de imágenes, realtime, migración de la web (no hay backend real en ella).

## Commits previstos (ejemplos)

```
CHORE: esquema supabase con tablas y relacion por padre
FEAT: rls por auth uid en todas las tablas
CHORE: seeds demo con prefijo sintetico
FEAT: repositorios remotos con cache local offline-first
FEAT: cola de sync diferida al recuperar conexion
FEAT: autenticacion de padre con supabase auth
CHORE: script de dump para backup manual en tier gratis
CHORE: workflow keep-alive contra la pausa de 7 dias
DOCS: setup reproducible del proyecto supabase
```

## Criterios de aceptación

- [ ] Con `USE_SUPABASE=false` (default) la app es 100% igual que antes — cero regresiones.
- [ ] RLS verificada: sin `parent_id` propio, la query devuelve vacío.
- [ ] Ninguna clave en el repo (solo `--dart-define`); grep de `service_role` limpio.
- [ ] Escrito el dump y el keep-alive funcionando.
- [ ] `flutter analyze` 0 issues; tests de la cola de sync en verde.
