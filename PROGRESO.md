# PROGRESO — BlueTalk: rediseño + control parental (piloto)

Rama: `feat/rediseno-y-control-parental` (creada desde `main` en `cdce74b`).
Reglas de recursos (§0) aplicadas a partir de la FASE 1: `gradle.properties`
aún NO ajustado (queda en Fase 4, paso 1, antes de tocar Gradle).

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
- Ajustar `android/gradle.properties` a los límites del §0 (queda para
  Fase 4, paso 1).
- AVD comprobado: `~/.android/avd/bluetalk_gama_baja.avd` existe. El binario
  del emulador **no** está en el PATH: usar
  `~/android-sdk/emulator/emulator` (SDK en `~/android-sdk`).

### Carga medida al cerrar

```
17:08:28  up 5:24   load average: 2,07 / 1,50 / 1,72   (16 hilos, 13 GB)
```

---

**FIN DE LA FASE 1. Esperando confirmación para pasar a la FASE 2 (diseño).**
