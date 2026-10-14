# BlueTalk — Guía para agentes (EMPIEZA AQUÍ)

App Flutter (Android) de comunicación aumentativa (AAC) para niñas y niños autistas, con modo padre. Offline, sin cuentas, sin red. Objetivo: APK funcional y publicable en Play Store.

## Qué hacer, en este orden

1. Lee `docs/informes/auditoria-general.md` (estado real del proyecto y por qué).
2. Ejecuta `docs/plan/10-fase0-funcional.md` (9 pasos, uno por commit). **Hazlo completo antes de nada más.**
3. Ejecuta `docs/plan/11-fases-1-a-3-excelencia.md` (Fases 1, 2 y 3). Lee su §0 (estándar de ingeniería y reglas de honestidad) **antes** de escribir código: aplica a todo.
4. Al terminar cada fase: escribe `docs/informes/faseN-evidencia.md`, invoca al subagente `revisor` (`.opencode/agents/revisor.md`) y corrige lo grave.

Nadie te va a revisar sobre la marcha. **Tu informe de evidencia es la única prueba de que el trabajo está hecho.** Hazlo honesto: lo no verificado se declara como NO VERIFICADO.

## Primer comando

`git status --short`. Hay documentación y código sin commitear (`??`). El Paso 1 de la Fase 0 los commitea; incluye `AGENTS.md` y `docs/plan/11-*.md` en ese commit de documentación (`DOCS: auditoria general y plan de fase 0`).

## Reglas duras (resumen; completas en `docs/plan/00-PLAN-MAESTRO.md` §5–6)

- **Funcional de verdad:** nada está hecho hasta que lo ejecutaste y viste la salida. Compilar no es funcionar.
- Antes de cada commit: `flutter analyze` (0 problemas) y `flutter test` (todo verde).
- Commits: `TIPO: descripción en español` (≤70 caracteres; `FEAT FIX PERF TEST DOCS REFACTOR CHORE`). Sin texto de IA ni `Co-Authored-By`. Un cambio coherente por commit. Rutas concretas en `git add`, nunca `git add -A`.
- **Nunca `git push`**, nunca publicar, nunca crear cuentas ni claves. Ni inventar contraseñas, datos personales, nombres o datos de menores.
- Sin red, sin analítica, sin anuncios, sin cuentas. Sin ARASAAC (licencia no comercial); pictogramas: Mulberry (CC BY-SA 4.0).
- Sin dependencias nuevas que el plan no justifique.
- Si el código contradice un plan: detente, anótalo en `docs/informes/faseN-notas.md` y propone el cambio mínimo.
- Si una decisión es del usuario (modelo de negocio, `applicationId`, keystore, públicos objetivo, publicar la política de privacidad): **no decidas**; deja la pregunta escrita en `docs/informes/decisiones-pendientes.md` y continúa con lo que no dependa de ella.

## Principios de producto (no negociables, es un público vulnerable)

- Lenguaje literal, sin metáforas; navegación fija y predecible.
- **Ningún sonido ni voz automática**: la voz solo suena bajo toque.
- Objetivos táctiles ≥48 dp, contraste AA, modo calma (grises + sin animaciones) siempre respetado.
- El vocabulario nuclear va **siempre en la misma posición**; nunca se reordena.
- Datos del menor solo en el dispositivo. Observaciones siempre con "orientativa, no es diagnóstico".

## Mapa del repositorio

| Ruta | Qué hay |
|---|---|
| `lib/app/` | Router, DI (`di.dart`), shell, tema raíz |
| `lib/core/` | Tema, tokens de color, modo calma, widgets comunes |
| `lib/data/` | Modelos, contratos (`repos.dart`), repos locales (`mock_repos.dart`, seeds) |
| `lib/features/` | `comunicador`, `juegos`, `rutinas`, `salud`, `entorno`, `padre`, `ajustes`, `onboarding` |
| `assets/seed/` | JSON de categorías, pictogramas, cuentos, horario, reglas |
| `docs/plan/` | Planes (00 maestro, 01–09 por área, **10 Fase 0, 11 Fases 1–3**) |
| `docs/informes/` | Informes (auditoría, evidencias de fase) |
| `docs/legal/` | Términos y privacidad (no son asesoría legal) |

Persistencia: `SharedPreferences` (decisión del MVP). Estado: Riverpod. Rutas: go_router.

## Comandos útiles

```bash
flutter analyze
flutter test
flutter test test/rutinas/ --plain-name "texto del test"
flutter build apk --debug
flutter build apk --release --split-per-abi   # tras la Fase 3 (firma)
```

## Al terminar TODO

Escribe `docs/informes/cierre.md` con: qué quedó hecho y verificado, qué es NO VERIFICADO (y requiere teléfono físico), qué decisiones esperan al usuario, y el siguiente paso recomendado. Eso es lo que leerá el usuario.
