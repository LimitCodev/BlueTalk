# BlueTalk — Plan maestro de desarrollo (APK MVP)

**Estado:** PARA REVISIÓN 1x1 (empezar leyendo este → 01 → 02 … → 08)
**Objetivo:** APK Android instalable que corra bien en celulares de bajos recursos (Android Go, 1–2 GB RAM), con camino claro a Play Store. MVP con datos 100% mock/ficticios.

---

## 1. Resultado del análisis de la web actual (bluetalk.lovable.app)

Se analizó el bundle desplegado (`index-4jkF9vaO.js`, 836 KB):

- **Stack actual:** React + Vite + TanStack Query + recharts + lucide-react + `speechSynthesis`.
- **Rutas existentes:** `/` (bienvenida + nombre), `/pictogramas`, `/categorias/:id` (comunicador AAC), `/aprende/{memoria,cuentos,artista}` (juegos), `/horario` (rutinas), `/estadisticas`, `/anuncios`, sección Premium con PIN.
- **"Base de datos":** NO hay Supabase en el build. Todo vive en `localStorage` (`bluetalk_user`, `bluetalk_schedule_v2`, `bt_completed_stories`, `memoria_unlocked`).
- **Features nuevas (no existen aún):** control parental, enfoque de salud, términos y condiciones, diagnóstico/sugerencias en modo padre, pantalla de entorno/colegio.
- **Decisión:** reconstruir desde cero en Flutter con arquitectura, seguridad y optimización mejores que la web.

## 2. Decisiones cerradas (con usuario)

| # | Decisión |
|---|---|
| 1 | Reconstruir el proyecto con mejores prácticas, seguridad y optimización |
| 2 | **Flutter (Dart)** como lenguaje/framework del APK |
| 3 | **Supabase free desde el inicio** (500 MB, auth 50k MAU) |
| 4 | **Paleta: celeste pastel** |
| 5 | **Modo calma:** escala de grises + animaciones desactivadas (interruptor) |
| 6 | Sin nombres reales de miembros, sin datos reales, datos mockeados para el MVP |
| 7 | **1 commit por cambio coherente**, mensaje preciso y corto, sin textos de IA |

## 3. Stack técnico y por qué

| Área | Elección | Por qué | Alternativa descartada |
|---|---|---|---|
| App | **Flutter 3.x + Dart 3** | Compila a ARM nativo (AOT), buen rendimiento en gama baja, un solo código para Android/iOS futuro, MVP rápido | **Kotlin + Compose:** máximo rendimiento Android puro, pero solo Android y más lento de desarrollar. **React Native:** peor en gama baja (puente JS). **Rust:** no hay hot-path que lo justifique; si aparece, se integra después vía FFI (`flutter_rust_bridge`) |
| Estado | Riverpod | Tipado, sin bugs de context, moderno | Provider (más viejo), Bloc (más verboso) |
| Rutas | go_router | Declarativo, estándar Flutter | Navigator manual |
| BD local | **Drift (SQLite)** | Offline-first obligatorio (aula/conexión intermitente), tipado, migraciones | Hive (sin SQL), Isar (madurez dudosa) |
| BD remota | Supabase free | Decisión del usuario: auth + Postgres + RLS | Neon (sin auth integrado) |
| Voz (TTS) | flutter_tts | Usa la voz del sistema, **funciona offline** | — |
| Gate de padre | local_auth + PIN hasheado | Biométrico si hay, PIN como base | Solo PIN |
| Pictogramas | **Mulberry Symbols (CC BY-SA 4.0)** como set principal + **Twemoji (CC BY 4.0)** como complemento; pantalla de créditos obligatoria | Libre para uso comercial → cero riesgo en Play. Hecho específicamente para AAC, en SVG | **ARASAAC descartado** (CC BY-NC-SA = no comercial; riesgo legal si hay Premium/pagos). OpenMoji queda como reserva |

**Identidad Android (confirmar en revisión):** paquete `com.limitcodev.bluetalk`, `minSdk 24` (Android 7, cubre gama baja vieja), `targetSdk` = último exigido por Play (36 en 2026, verificar al compilar), versionado semver `0.1.0` + `versionCode`.

### 3.1 Métodos de rendimiento verificados (investigación 2026)

| Método | Aplicación en BlueTalk |
|---|---|
| **Impeller** (renderer por defecto desde Flutter 3.27) | No hacer precarga de shaders SkSL — consejo obsoleto, ahorramos trabajo |
| **`Isolate.run()` / `compute()`** | `async/await` NO mueve trabajo CPU-bound del hilo principal → parsing de JSON grande y lecturas de BD a isolates (causa #1 de jank en gama baja) |
| **`cacheWidth` en imágenes** | Decodificar al tamaño mostrado: hasta 100x menos memoria (4.4 MB → 330 KB) |
| **Tope de `ImageCache`** | 50 imgs / 20 MB en arranque si RAM ≤3 GB → evita el Low Memory Killer |
| **AAB + `--split-per-abi`** | Play entrega solo el ABI del dispositivo (~30-40% menos descarga) |
| **Deferred components** | **Descartado**: complejidad > beneficio en app de este tamaño |
| **Riverpod `.select()`** | Rebuilds granulares: solo se redibuja lo que cambió |
| **Perfilado en dispositivo real** | El emulador miente. Objetivos: <8 ms build/raster, <150 MB RAM pico, <3 s arranque |
| **Animaciones adaptativas** | Detectar RAM y degradar animaciones; el Modo calma ya respeta `MediaQuery.disableAnimations` |

### 3.2 Cache/Redis — decisión: **NO lleva Redis**

Supabase no incluye Redis en su free tier (solo un wrapper FDW de lectura; ellos usan Upstash internamente para sus Edge Functions). BlueTalk es offline-first con poco tráfico sincronizado: PostgREST + Drift local es suficiente. Redis sería complejidad sin beneficio. **Queda descartado**; si en el futuro hay Edge Functions con tráfico real, evaluar **Upstash Redis free** (256 MB, 500K cmds/mes, sin tarjeta) para rate limiting.

## 4. Paleta celeste pastel + Modo calma (tokens)

Tokens base (el agente `base-flutter` implementa y verifica contraste AA):

| Token | Valor inicial | Uso |
|---|---|---|
| `bg` | `#F3FAFF` (off-white celeste) | Fondo. Nunca blanco puro (deslumbre) |
| `surface` | `#FFFFFF` | Tarjetas |
| `primary` | `#7FC9EA` (celeste pastel) | Botones, acentos |
| `primaryInk` | `#12333B` (tinta oscura) | Texto sobre primary (contraste AA) |
| `text` | `#1F3A44` | Texto principal sobre bg |
| `success` / `warning` / `error` | versiones suaves y desaturadas | Estados (texto sobre ellos ≥4.5:1) |

Reglas de contraste (WCAG 2.2 AA): **≥4.5:1 texto, ≥3:1 elementos de UI**. Test unitario que valida los tokens.

**Modo calma (especificación exacta):**
1. `ColorFiltered` con `BlendMode.saturation = 0` sobre el árbol → toda la UI en grises.
2. Animaciones a 0: transiciones de ruta instantáneas, sin animaciones implícitas, sin parallax/partículas.
3. Sin autoplay de audio; silencia sonidos no esenciales.
4. Respeta automáticamente "Eliminar animaciones" del sistema Android (`MediaQuery.disableAnimations`).
5. Persistente (SharedPreferences) + toggle en Ajustes **y** botón visible en el shell principal.

## 5. Reglas duras (aplican a TODOS los agentes)

1. **Cero datos/nombres reales.** Laura → no aparece. Colegio San Miguel → "Colegio Demostración Norte". Contactos, teléfonos, emails → inventados y marcados como demo. Git: solo el nick `LimitCodev`.
2. **Sin PII infantil.** Perfil de niño = apodo local opcional + avatar picto. Nada de apellidos, emails, fotos, ubicación.
3. **Commits:** convención de la sección 6. Sin `Generated with Claude`, sin `co-authored-by` de IA, sin párrafos explicativos largos.
4. **`flutter analyze` 0 issues + `flutter test` en verde antes de cada commit.**
5. **`pubspec.yaml` congelado en Ola 2** (las deps base ya están puestas). Si falta una → pedir al agente principal, no editar.
6. **Ningún agente hace `git push`.** El push es por hito, tras revisión.
7. **Rendimiento gama baja:** `const` donde aplique, imágenes WebP ≤128 KB, listas con lazy loading, sin libs de animación pesadas (Rive/Lottie), nada pesado en `build()`.
8. **Accesibilidad infantil/autismo:** targets táctiles ≥48dp, lenguaje literal (sin metáforas), navegación fija y predecible, sin autoplay de voz (TTS bajo taps del usuario).

## 6. Convención de commits

Formato: `TIPO: descripción concreta en español` (≤70 caracteres, sin punto final).

| Tipo | Cuándo |
|---|---|
| `FEAT` | Funcionalidad nueva |
| `FIX` | Corrección (seguridad, bug, contraste) |
| `PERF` | Rendimiento/tamaño |
| `TEST` | Tests |
| `DOCS` | Documentación/legal/checklists |
| `REFACTOR` | Reordenar sin cambiar comportamiento |
| `CHORE` | Infra, scripts, config, dependencias |

- **1 commit = 1 cambio coherente.** Un agente puede hacer varios commits durante su tarea.
- Opcional: cuerpo de **1 a 3 líneas** concretas (qué se incorporó). Nada más.
- Área en MAYÚSCULAS cuando aporta claridad.

| ✅ Bueno | ❌ Malo |
|---|---|
| `FEAT: pictogramas offline con barra de frase` | `Update files` |
| `FIX: login seguridad por medio de la libreria local_auth` | `feat: add stuff` |
| `PERF: imagenes webp y cache para gama baja` | commit con párrafo generado por IA |
| `DOCS: terminos y condiciones de uso` | `chore: cambios varios` |

## 7. Estructura del repo

```
lib/
├── main.dart
├── app/                 # App, router, inyección de dependencias, flags (USE_SUPABASE)
├── core/
│   ├── theme/           # tokens de color, tema, modo calma
│   └── utils/           # constantes, helpers, hashes
├── data/
│   ├── contracts/       # interfaces de repositorios
│   ├── models/          # modelos de dominio (manuales, con fromMap/toMap)
│   ├── local/           # Drift + seeds mock → FUENTE DE VERDAD del MVP
│   └── remote/          # cliente Supabase + sync (Ola 2)
├── features/
│   ├── onboarding/      # bienvenida, nombre local
│   ├── comunicador/     # AAC: categorías, pictos, frase, TTS
│   ├── juegos/          # memoria, cuentos, artista, avance
│   ├── rutinas/         # horario, recordatorios
│   ├── salud/           # check-in emocional, hábitos
│   ├── entorno/         # pantalla "Mi escuela" (datos ficticios)
│   ├── padre/           # gate PIN, dashboard, observaciones, control, legal
│   └── ajustes/         # modo calma, voz, tamaño de texto, créditos
assets/
├── pictos/              # set aprobado (plano, nombre prefijado)
├── seed/                # categorías, cuentos, horario mock (JSON)
└── fonts/
supabase/                # migrations/ + seed.sql
docs/
├── plan/                # este plan y los planes por agente
├── legal/               # T&C, privacidad
├── play/                # checklist de publicación
└── informes/            # informes del revisor
scripts/                 # db-dump, keep-alive, build
```

## 8. Ejecución por olas (evita conflictos entre agentes en paralelo)

| Ola | Agente | Rutas dueñas (los demás no tocan) | Esfuerzo |
|---|---|---|---|
| 0 | **planes** (este documento) | `docs/plan/**` | — |
| 1 | `base-flutter` | `pubspec.yaml`, `lib/{main,app,core,data/{contracts,models,local},features/{onboarding,ajustes}}`, `assets/seed`, `test/core` | **XL** |
| 2 (paralelo) | `aac-comunicador` | `lib/features/comunicador/**`, `assets/pictos/**`, `test/comunicador/**` | L |
| 2 (paralelo) | `juegos` | `lib/features/juegos/**`, `test/juegos/**` | L |
| 2 (paralelo) | `rutinas-salud` | `lib/features/{rutinas,salud,entorno}/**`, `test/rutinas/**` | M |
| 2 (paralelo) | `modo-padre` | `lib/features/padre/**`, `docs/legal/**`, `test/padre/**` | L |
| 2 (paralelo) | `backend-supabase` | `lib/data/remote/**`, `supabase/**`, `scripts/**`, `docs/backend/**`, `.github/workflows/keep-alive.yml` | M |
| 3 | `apk-release` | `android/**`, `docs/play/**`, `scripts/build*` | M |
| todo | `revisor` | `docs/informes/**` (solo lectura del resto) | continuo |

- **`pubspec.yaml` congelado en Ola 2** (deps declaradas en Ola 1).
- Orden de revisión de planes: 00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08.

## 9. Flujo de revisión 1x1

```
Usuario aprueba plan 00..08
  → Ola 1: base-flutter trabaja y commitea
    → revisor emite informe (severidad + archivo:línea)
      → correcciones del agente (commits FIX)
        → usuario revisa la entrega (1x1)
          → Ola 2 (paralelo) … idem
            → Ola 3: APK de release
              → checklist Play Store
```

## 10. Criterios de aceptación del MVP

- [ ] Instala y corre en emulador API 24 con 1 GB RAM; arranque en frío <3 s.
- [ ] Flujo del niño (comunicar, juegos, rutinas) **100% offline**.
- [ ] Modo calma grisa toda la UI con animaciones apagadas; persiste al reiniciar.
- [ ] Gate de padre: PIN hasheado + intentos fallidos bloqueados; biométrico opcional.
- [ ] Dashboard de padre con métricas locales + observaciones con disclaimer "no es diagnóstico médico".
- [ ] T&C + privacidad con consentimiento parental versionado.
- [ ] Cero nombres/datos reales (grep verificado antes de release).
- [ ] `flutter analyze` 0 issues; tests en verde.
- [ ] APK directo ≤15 MB por ABI; AAB listo para Play.

## 11. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Supabase pausa tras 7 días sin tráfico | Workflow `keep-alive` (cron diario) + `scripts/db-dump.sh` (free tier sin backups automáticos) |
| Licencia de pictogramas al publicar | Solo sets abiertos con pantalla de créditos |
| Rendimiento en gama baja | Auditoría en Ola 3 sobre emulador API 24/Android Go; sin libs pesadas |
| Play "Designed for Families" + Data Safety | Checklist en `docs/play/CHECKLIST.md`; privacidad hospedada gratis en GitHub Pages |
| Voces TTS sin español offline | Instrucción al usuario de descargar voz del sistema; fallback con aviso |

## 12. Fuera de alcance del MVP

iOS · pagos/suscripciones reales · multi-idioma · control profundo del OS (Usage Stats) · sincronización multi-dispositivo en tiempo real · telemetría · teoría de juegos con IA.

## 13. Preguntas abiertas (responder al revisar este plan)

1. ¿Paquete `com.limitcodev.bluetalk` bien?
2. ¿Cuenta de Google Play lista ($25 único)? ¿Nombre visible en tienda?
3. ¿iOS en el futuro cercano? (afecta poco, Flutter lo cubre)
4. ~~Pictogramas~~ → **Cerrado:** Mulberry Symbols principal + Twemoji complemento (probar primero con una muestra antes de integrar).
5. Recordatorios de horario: ¿notificaciones del sistema o solo aviso in-app en MVP?
6. **Entorno:** `flutter doctor` reporta **Android SDK ausente** → hay que instalarlo (Android Studio o cmdline-tools) antes de poder compilar el APK. Chrome ausente (no bloquea, la app es Android).
