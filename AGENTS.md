# BlueTalk — Guía para agentes (EMPIEZA AQUÍ)

App Flutter (Android) de comunicación aumentativa (AAC) para niñas y niños autistas, con modo padre. Offline, sin cuentas, sin red. Objetivo: APK funcional y publicable en Play Store.

## Qué hacer, en este orden

1. Lee `docs/informes/auditoria-general.md` (estado real) y el §0 de `docs/plan/11-fases-1-a-3-excelencia.md` (estándar de ingeniería y honestidad; aplica a todo).
2. **Ya cerrado:** plan 10 (Fase 0) y plan 11 Fase 1 (`docs/informes/fase1-evidencia.md`). No lo repitas.
3. Ejecuta lo que queda **en este orden** (pensado para dar un APK de prueba mejor cuanto antes y no rehacer trabajo):

| Etapa | Qué | Plan | Por qué en este lugar |
|---|---|---|---|
| A | Fallos vistos en el teléfono: **Atrás (P1)**, **dibujo (P2)**, pruebas de nombre y rutinas (P6.1), **instalación y APK liviano (P7)** | 13 | Son lo que el dueño ya sufrió. Cierra con un APK de prueba nuevo. |
| B | **Marca y logo (P3)** y **colores personalizables (P4)** | 13 | Todo lo visual posterior usa la paleta nueva; hacerlo después obligaría a rehacer pantallas. |
| C | Vocabulario 200+, Primero–Luego, fotos propias, copia de seguridad (Fase 2) | 11 | Contenido del comunicador, ya con la paleta final. |
| D | Estabilizar (Fase 0 del plan 12; verifica qué ya está hecho), primera instalación adulto-primero (F1), canal nativo (F2), inicio del niño y salida protegida (F3) | 12 | Base del modo niño. Necesita Atrás de la etapa A funcionando. |
| E | Registro de uso (F4), **panel visual (P5)**, **emociones y mejoras de reseñas (P6.2–6.4)**, recomendaciones (F5–F6) | 12 y 13 | El panel de P5 pinta datos que solo existen después de F4. Se hacen juntos. |
| F | Vocabulario y pictogramas (F7 del plan 12), identidad y firma para tienda (Fase 3 del plan 11; el ícono ya viene de P3), APK final y checklist en teléfono (F8) | 12 y 11 | Cierre y publicación; lo último porque depende de todo lo anterior. |

4. Al terminar cada etapa: escribe `docs/informes/<etapa>-evidencia.md`, invoca al subagente `revisor` (`.opencode/agents/revisor.md`) y corrige lo grave. Un commit por paso.
5. Si dos planes se pisan (ej.: ícono en plan 11 Fase 3 y plan 13 P3; copia de seguridad en plan 11 §2.4 y plan 13 P6.2), **hazlo una sola vez**, en la primera etapa donde aparece, y anótalo en el informe.

## Ejecución desatendida (norma cuando el usuario duerme)

- **Latido:** tras cada commit, añade **una línea** a `estado-vivo.log` (raíz, ignorado por git): `AAAA-MM-DD HH:MM | etapa | paso | analyze=OK/FALLA | test=N/N | nota corta`. Sin pegar logs. Al cerrar una etapa añade `ETAPA X CERRADA`; al terminar todo, `FIN`.
- **Pide pocos tokens:** no relances comandos que ya pasaron, no releas archivos grandes enteros, no hagas búsquedas amplias si ya sabes dónde está. Un solo emulador a la vez; ciérralo al terminar.
- **Corte de seguridad:** si el mismo paso falla **3 veces seguidas**, o `analyze`/`test` siguen en rojo tras 3 intentos, **detente**: escribe `BLOQUEADO | paso | motivo` en `estado-vivo.log` y en `docs/informes/decisiones-pendientes.md`, y no sigas con otros pasos que dependan de él.
- Nada de `git push`, cuentas, claves ni instalar dependencias fuera del plan (ya es regla dura).
- Si en `estado-vivo.log` aparece una línea `PARAR` escrita por el usuario, termina el paso en curso, haz commit si está verde y detente.

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
