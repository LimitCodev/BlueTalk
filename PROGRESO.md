# PROGRESO — BlueTalk: rediseño + control parental (piloto)

Rama: `feat/rediseno-y-control-parental` (creada desde `main` en `cdce74b`).
Reglas de recursos (§0) aplicadas desde el commit `d28df52`:
`android/gradle.properties` limita Gradle a 4 hilos y 2 GB, y
`scripts/gradle-limite.sh` envuelve cada comando pesado en
`systemd-run --user --scope -p CPUQuota=400% -p MemoryMax=6G nice -n 10
taskset -c 0-3`.

---

## FASE 1 — Auditoría de lo que ya existe (cerrada)

Comandos de partida:

```
git status --short   → 25 modificados + 14 sin seguir
git log --oneline    → HEAD cdce74b (DOCS: mejoras del modo padre…)
```

Verificación de "compila": `flutter analyze` (Dart, sin Gradle, sin emulador,
envuelto en `taskset -c 0-3`). Al empezar: **2 avisos, 0 errores**, ambos en
un test (`test/padre/uso_telefono_test.dart`). Ya corregidos, ver "Cierre".

### Archivos modificados

| Archivo | Estado | Notas |
|---|---|---|
| `android/app/src/main/AndroidManifest.xml` | Completo | +`PACKAGE_USAGE_STATS`, `INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE(_SPECIAL_USE)`, `<queries>` de apps lanzador y servicio `.FiltroWebVpnService` |
| `android/.../MainActivity.kt` | Completo | Conecta `FiltroWebChannel` y `UsoTelefonoChannel`, los dispone en `onDestroy` |
| `lib/core/theme/app_colors.dart` | Completo | 6 paletas con AA verificado por test |
| `lib/core/theme/app_theme.dart` | Completo | Tema + modo calma |
| `lib/core/widgets/logo_bluetalk.dart` | Completo | |
| `lib/features/comunicador/comunicador_screen.dart` | Completo | |
| `lib/features/comunicador/picto_tile.dart` | Completo | |
| `lib/features/onboarding/onboarding_screen.dart` | Completo | |
| `lib/features/padre/control/control_screen.dart` | Completo | Enlaces a FiltroWeb y UsoTeléfono + estado de permisos |
| `lib/features/padre/dashboard/resumen_screen.dart` | Completo | Bloque `_UsoTelefonoResumen` |
| `lib/features/padre/legal/*` | Completo | Textos de privacidad/permisos |
| `docs/legal/PRIVACIDAD.md` | Completo | |
| `docs/legal/TERMINOS_Y_CONDICIONES.md` | Completo | |
| `docs/play/permisos.md` | Completo | |
| `docs/informes/decisiones-pendientes.md` | Completo | |
| `pubspec.yaml` | Completo | +`assets/brand/`, fuente Nunito variable |
| `test/core/router_test.dart`, `tokens_test.dart`, `features/ajustes_test.dart`, `padre/harness.dart`, `padre/legal_test.dart` | Completo | |

### Archivos nuevos

| Archivo | Estado | Notas |
|---|---|---|
| `android/.../FiltroWebVpnService.kt` (750) | Completo | VPN que solo intercepta DNS, reenvía al DNS de la red con `protect`, NXDOMAIN a los bloqueados, log de 100 bloqueos en prefs locales. Compilación Kotlin **NO VERIFICADA** (Fase 1 no compila) |
| `android/.../FiltroWebChannel.kt` (124) | Completo | Puente Dart↔servicio |
| `android/.../UsoTelefonoChannel.kt` (288) | Completo | `UsageStatsManager` + icono en base64 |
| `lib/features/padre/filtro_web/` (4 archivos, 1281) | Completo | Modelo, controlador, gateway y pantalla |
| `lib/features/padre/monitoreo/` (4 archivos, 705) | Completo | Resumen por periodo desde `UsageStats` |
| `test/padre/filtro_web_test.dart` (397) | Completo | |
| `test/padre/uso_telefono_test.dart` (246) | Completo | Avisos corregados |
| `integration_test/filtro_web_test.dart` (64) | Completo | Requiere dispositivo |
| `integration_test/pbkdf2_bench_test.dart` (27) | Completo | Requiere dispositivo |
| `integration_test/perfilado_rejilla_test.dart` (39) | Completo | Requiere dispositivo |
| `assets/brand/logo_bluetalk.png` | Completo | |
| `assets/fonts/Nunito-Variable.ttf`, `OFL.txt` | Completo | |

### Código muerto / a medias detectado

- **Ningún `TODO`, `FIXME` ni `UnimplementedError`** en las zonas nuevas.
- Comentario en `filtro_web_model.dart` y `filtro_web_screen.dart` cita
  `docs/plan/14-filtro-web.md`: **ese archivo no existe**. Documentación rota.
- Lista de dominios **hardcodeada en Dart** (`filtro_web_model.dart`), no
  empaquetada en `assets/` ni con `docs/LISTAS.md` (lo pide la Fase 3.3).

### Huecos frente a la Fase 3 del encargo

| Subtarea | Estado |
|---|---|
| 3.1 PIN 4–6 dígitos en `EncryptedSharedPreferences` | **Parcial**: PIN con PBKDF2-HMAC-SHA256 + sal y bloqueo escalonado tras 5 fallos, pero guardado en `SharedPreferences`, no en `EncryptedSharedPreferences` |
| 3.1 "El niño no puede desinstalar la app" | **No hecho**: falta `DeviceAdminReceiver` |
| 3.2 Asistente de permisos (onboarding del padre) | **No hecho**: solo 2 `ListTile` en Control; faltan AccessibilityService, superposición, DeviceAdmin, batería y avisos |
| 3.3 Filtro DNS con lista blanca/negra | **Hecho** |
| 3.3 SafeSearch forzado (Google/Bing/DuckDuckGo) | **No hecho** |
| 3.3 Palabras clave en búsquedas | **No hecho** (solo DNS, no se lee la barra del navegador) |
| 3.3 Perfiles por edad (6–9, 10–13, 14–17) | **No hecho** |
| 3.3 Lista pública citada en `docs/LISTAS.md` + copia en `assets/` | **No hecho** |
| 3.4 Límites diarios por app, horarios, "pedir más tiempo" | **No hecho** |
| 3.5 Historial local (Room) + gráfica día/semana + línea de tiempo | **Parcial**: solo resumen por periodo en vivo desde `UsageStats`; nada persiste en Room |
| 3.5 Sesión de confianza "mientras te lo doy" | **No hecho** |
| 3.5 Retención configurable | **No hecho** |
| 3.6 Textos de transparencia y privacidad | **Hecho** (docs legales actualizados; falta el texto visible para el niño en la pantalla del propio teléfono) |

### Preguntas que quedan para el dueño

1. ¿Se añade `flutter_secure_storage` para mover el PIN a
   `EncryptedSharedPreferences`? Es una dependencia nueva; la regla dura del
   repo prohíbe dependencias no justificadas, y este es un requisito del
   encargo. Sin ella se queda en `SharedPreferences` (que en Android ya cifra
   el archivo con la clave del dispositivo, pero menos que keystore).
2. ¿Se añade la fase extra de Device Owner / perfil gestionado que ofreces?
3. ¿Se añade el bloqueo de DNS-over-HTTPS propio (navegadores con su DNS)?
   Dado que el niño usa un AVD simple, propongo: **sí, pero solo con el
   ajuste global de "DNS privado" forzado vía Device Owner** (sin eso no se
   puede bloquear por app sin root); si no, se documenta el límite.
4. ~~¿Dónde está el AVD `bluetalk_gama_baja`?~~ Resuelto: existe en
   `~/.android/avd/bluetalk_gama_baja.avd`; el emulador está en
   `~/android-sdk/emulator/emulator`.

### Cierre de la FASE 1

Todo el trabajo suelto del agente anterior estaba sin commitear. Se revisó y
se separó en cambios coherentes (una responsabilidad por commit):

| Commit | Qué |
|---|---|
| `105e307` | `DOCS:` auditoría en PROGRESO.md |
| `4293f46` | `TEST:` quita los 2 avisos del doble del gateway de uso |
| `e41cb68` | `FEAT:` identidad de la web: paleta, Nunito, logo, tarjetas |
| `9cd0798` | `TEST:` contraste de barra superior, tarjetas y nombre del tema |
| `1f9451d` | `DOCS:` permisos y privacidad del filtro y del uso de teléfono |
| `e8a6fb1` | `FEAT:` filtro de páginas con VPN local DNS |
| `ac89c2f` | `FEAT:` diagnóstico de uso por app (UsageStats) |
| `667f8e2` | `FEAT:` entradas del filtro y del diagnóstico en el panel |

Árbol limpio (`git status` vacío).

Verificado en esta fase:

- `flutter analyze` → **0 problemas**.
- `flutter test test/padre/uso_telefono_test.dart test/padre/filtro_web_test.dart`
  → **28/28 en verde**.
- **NO VERIFICADO**: compilación Kotlin de `FiltroWebVpnService.kt`,
  `FiltroWebChannel.kt` y `UsoTelefonoChannel.kt`; comportamiento en
  dispositivo. Es Fase 4.

### Pendiente para la FASE 2

- `docs/plan/14-filtro-web.md` no existe y lo citan los comentarios del
  código: hay que redactarlo (o quitar la cita).
- AVD comprobado: `~/.android/avd/bluetalk_gama_baja.avd` existe. El binario
  del emulador **no** está en el PATH: usar
  `~/android-sdk/emulator/emulator` (SDK en `~/android-sdk`).

### Carga medida al cerrar

```
17:08:28  up 5:24   load average: 2,07 / 1,50 / 1,72   (16 hilos, 13 GB)
```

---

**FIN DE LA FASE 1. Esperando confirmación para pasar a la FASE 2 (diseño).**

---
---

# FASE 2 — Diseño: igualar la web oficial

Confirmada por el dueño el 2026-10-21. Decisiones tomadas entonces:

1. Sí se añade `flutter_secure_storage` para el PIN → **va en la Fase 3a**.
2. La Fase 3 se divide en **3a / 3b / 3c** con parada entre cada una.
3. El DNS-over-HTTPS propio del navegador **no se bloquea**: se documenta el
   límite (no se añade fase de Device Owner).

## 2.1 Extracción de la web

Descarga única con `curl -s -L` (§2.1). Originales en `docs/branding/`:

| Archivo | Qué es |
|---|---|
| `index.html` | 12 014 B, HTTP 200 |
| `index.css` | 74 174 B, HTTP 200 (Tailwind + variables del tema) |
| `og-preview.png` | 95 007 B, 1920×1080, el `og:image` |
| `WEB-EXTRACCION.md` | Paleta, tipografía, radios y correspondencia con la app |

Lo que **no** se pudo extraer (dicho, no inventado):

- **Sin favicon, sin `<img>`, sin `<svg>`.** El `<head>` solo tiene metas.
- **Sin archivo de logo.** El único original es el logo de ~40 px **dentro**
  de `og-preview.png`; a esa resolución no se regenera un ícono adaptativo
  fiel. **El ícono actual (derivado del cartel) se conserva.** Ver pregunta
  al dueño abajo.
- **La web no carga Nunito**: declara `font-family: Nunito, sans-serif` pero
  tiene **0 `@font-face`** y ningún enlace a Google Fonts. La app sí
  empaqueta Nunito: es más fiel al diseño que el sitio.
- **No se copian las variables `--sidebar-*`**: existen por la plantilla base
  pero no se usan en la página publicada.

## 2.2 Fuente única de verdad

Ya existía (`lib/core/theme/app_colors.dart` + `app_theme.dart`). En esta
fase se completó con los valores extraídos y se añadió **modo oscuro**: la
web sí lo tiene (`.dark` completo), así que la app también (§2.3).

| Commit | Qué |
|---|---|
| `9fad915` | `DOCS:` paleta, tipografía y radios extraídos |
| `73f57df` | `FEAT:` modo oscuro de la web como 7.ª paleta |
| `8f50081` | `FEAT:` barras de progreso y estadísticas siguen la paleta |
| `b675ea8` | `FEAT:` pictogramas tiñen con su categoría, como la web |
| `7d41f6c` | `FIX:` tarjetas de categoría del Inicio en modo oscuro |
| `d28df52` | `CHORE:` Gradle limitado a 4 hilos y 2 GB (§0) |

Cambios de estructura: `AppColors` gana `brillo` y `borde` (antes
`AppColors.borde` era un estático único, ahora es de paleta y el estático se
llama `bordeNeutro`). `ColoresCategoria` gana `relleno()`, `bordeSobre()` y
`texto()`: la regla de color de la tarjeta vive en **un** sitio y la usan
tanto el Inicio como la rejilla de pictogramas.

## 2.3 Diferencias deliberadas con la web (todas por AA, documentadas)

| Dónde | La web | La app | Por qué |
|---|---|---|---|
| Botón de acción | `--primary #238EE7` + texto blanco | `#1574C1` + blanco | `#238EE7` con blanco da **3,45:1**, no pasa AA |
| Botón en oscuro | `#3095E8` + blanco (3,19:1) | `#3095E8` + `#171D26` (5,31:1) | El tinta oscura es el propio `--background` del `.dark` |
| Tarjeta de categoría en oscuro | sin definir (mantiene pasteles) | relleno = tono al 10 %, borde = 30 % | Un pastel sería un bloque claro sobre la página oscura |
| Etiqueta de categoría en oscuro | tono saturado (máx. 4,08:1) | `text` del tema (12,5:1) | Los `--cat-*` no llegan a 4,5:1 sobre `#1F2733` |
| Verde de acento | `--accent #37BEA7` | `Marca.verde #2FBFA3` | Es el verde del corazón del **logo**, no el teal. No se cambia sin confirmación |

## 2.4 Verificación en emulador (§2.6)

APK de depuración construido con los límites del §0 y **una sola** tanda de
emulador (`bluetalk_gama_baja`, API 28, `-no-window -gpu host -cores 2
-memory 2048`, `taskset -c 4-7`). Capturas en
`docs/informes/capturas/etapa-web/`:

| Captura | Qué se ve |
|---|---|
| `01-inicio-claro.png` | Inicio claro: tarjetas de categoría pastel |
| `02-emociones-claro.png` | Pictogramas con relleno/borde de su categoría |
| `03-inicio-oscuro.png` | Inicio oscuro: cada categoría con su tinte propio |
| `04-emociones-oscuro.png` | Pictogramas con la regla de alpha en oscuro |
| `05-oscuro-ajustes.png` | Selector con «Modo oscuro (como la web)» |

Comparación con `docs/branding/og-preview.png`: barra azul idéntica
(`#238EE7`), fondo `#F4F7FA` vs `#F5F7FA` (1/255), tarjetas con borde fino
del color de categoría y sin sombra, Nunito, esquinas redondeadas. Las
capturas se tomaron **después** del último commit.

**Defecto encontrado y corregido durante la verificación:** en modo oscuro
las tarjetas del Inicio seguían con pasteles claros (`7d41f6c`). Es exactamente
lo que está para comprobar la §2.6: sin captura no se habría visto.

## 2.5 Verificado / NO VERIFICADO

Verificado:

- `flutter analyze` → 0 problemas.
- `flutter test test/core/tokens_test.dart test/comunicador` → **49/49**.
- APK de depuración compilado: **38,5 s**, y con él se vio lo de arriba.
- Gradle quedó limitado a 4 hilos y 2 GB; el emulador a 2 núcleos en
  `taskset -c 4-7`. Ningún comando pasó de 4 hilos.

**NO VERIFICADO / límites:**

- El **ícono adaptativo y el splash no se regeneraron**. Cerrado el
  2026-10-21: el dueño aportó los dos originales (`docs/branding/
  favicon-web.ico`, 256×256, y `logo-wordmark.png`, 284×85) y **decidió
  conservar el ícono actual**, que deriva del wordmark y es vectorial.
  El favicon queda archivado como referencia de marca. §2.4 cumplida con
  «se conserva», no con «se regenera».
- El header de la app lleva el **título de la pestaña**, no el lema «Tu voz,
  siempre contigo» de la web. Es decisión de producto (una app no es una
  landing); no se cambia sin confirmación.
- No se comparó contra la web **en vivo renderizada**, solo contra la
  captura oficial y las variables del CSS.

### Preguntas cerradas con el dueño

- ~~Archivo original del logo~~ → aportado el 2026-10-21; ambos archivados
  en `docs/branding/`. Ícono adaptativo: **se conserva el actual**.

### Carga medida al cerrar la FASE 2

```
18:00:11  up 6:16   load average: 1,39 / 1,41 / 1,61
```

Emulador cerrado (`SIGTERM` a qemu; `adb emu kill` no sirve porque el token
de consola está oculto por el sandbox). Gradle y Kotlin daemon: `--stop`.

---

**FIN DE LA FASE 2. Esperando confirmación para pasar a la FASE 3a.**
