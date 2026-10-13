# 09 — Stack de frameworks y paquetes (propuesta)

Objetivo: sacar el máximo al proyecto (gama baja, offline, AAC, Play Store) sin inflar el APK ni la complejidad.
Investigación: octubre 2026. Versiones marcadas como "v" están verificadas en pub.dev a esta fecha.

## Regla de oro

- Cada paquete debe justificar su peso. Si la feature se resuelve con widgets nativos de Flutter, no entra librería.
- El `pubspec.yaml` se congela en Ola 1 → esta lista es la candidata definitiva.

---

## 1. Núcleo (Ola 1 — sí o sí)

| Área | Paquete | Ver. | Por qué |
|---|---|---|---|
| Runtime | Flutter stable | 3.44.4 v | Impeller por defecto → sin precarga de shaders (consejo obsoleto) |
| Estado | `flutter_riverpod` | 3.x | Compile-time safety; `.select()` = rebuilds mínimos (clave en gama baja) |
| Rutas | `go_router` | — | Shell fijo, rutas testables, deep links |
| BD local (fuente de verdad) | `drift` + `drift_flutter` | 2.35.1 v | Único con migraciones tipadas, streams reactivos e hilos integrados (`shareAcrossIsolates`). Hive/Isar originales **abandonados** (stable 2022/2023) — verificado 2026 |
| Preferencias | `shared_preferences` (API Async/WithCache) | 2.5.5 v | Solo flags pequeños; la API vieja está marcada legacy |
| Secretos/tokens | `flutter_secure_storage` | 11.2.0 v | Keystore/Keychain; nunca en preferencias |
| Pictos SVG | `flutter_svg` | 2.x | Render de Mulberry (ver §3 por el matiz de rendimiento) |
| Backend | `supabase_flutter` | — | Auth + Postgres + RLS, tras flag. Ya decidido |
| Voz (TTS) | `flutter_tts` | 4.2.5 v | es-ES, control de `speechRate` para ritmo pausado |
| PIN modo padre | `cryptography` / `crypto` | — | Argon2id/PBKDF2 + salt (plan 05) |
| Permisos/flags | `connectivity_plus` | — | Cola de sync al volver la red (plan 06) |

## 2. Comunicación AAC — potencial de voz

| Paquete | Fase | Qué aporta |
|---|---|---|
| `flutter_tts` | MVP | Hablar las frases ya está cubierto |
| `speech_to_text` | descartado por ahora | En Android depende del servicio Google; **no** es 100% offline |
| **`sherpa_onnx`** | **fase 2 (potencial real)** | STT 100% on-device en español, sin internet. Uso: el niño practica pronunciar y la app reconoce/retroalimenta. Costo: modelo ~40 MB → ofrecer como descarga opcional o aceptar APK más pesado |
| Piper TTS vía sherpa-onnx | fase 2 exploratoria | Voz neuronal offline más natural que la del sistema |

## 3. Pictos y render (matiz importante)

Investigación: `flutter_svg` 2.x delega en `vector_graphics`. Con muchas imágenes simultáneas (20–50 SVG en una grilla) hay jank documentado; desde 2025 existe **auto rendering strategy** (raster cache escalonado 1 por frame, umbral 2048²) que ya mitiga el pico. Medidas para BlueTalk:

1. Diseñar grillas de **≤12 pictos por pantalla** (no 50).
2. Precalentar el cache de SVG al entrar al comunicador (`svg.cache`).
3. Si el perfilado en dispositivo real marca pico → rasterizar los SVG de la grilla a PNG 128dp en build. No exige librería extra.

## 4. Animaciones y juegos

| Opción | Veredicto |
|---|---|
| Animaciones Flutter (`AnimatedContainer`, `AnimationController`) | **POR DEFECTO**: cero peso extra y respeta el Modo calma (`disableAnimations`) |
| **Rive** | Fase 2, solo si hay mascota interactiva. Benchmark Callstack: 25 MB RAM vs 49 MB de Lottie en nativo; archivos 5–10× menores para personajes |
| Lottie | Reserva si diseño ya manda JSON; mayor ecosistema |
| **Flame** | **NO por defecto**: los juegos AAC previstos (memoria, emparejar, secuencias) se resuelven con widgets + físicas. Flame solo si aparece arrastrar-soltar con físicas complejas |
| GIF / MP4 | Prohibido: pesado y no respeta el Modo calma |

## 5. Sonidos y refuerzos

- **`flutter_soloud`** → SFX de juegos con baja latencia. La comunidad reporta degradación de `audioplayers` con varios streams simultáneos. WAV/OGG cortos ≤100 KB.
- `just_audio`: NO (es para música/streaming).
- `HapticFeedback.lightImpact` como refuerzo extra sin gastar audio.

## 6. Horario y notificaciones

- **`flutter_local_notifications` + `timezone`** → plugin único. `awesome_notifications` es incompatible con él y su FCM gratis lleva watermark.
- Permisos: `POST_NOTIFICATIONS` (Android 13+), `RECEIVE_BOOT_COMPLETED` (reprogramar tras reboot), `SCHEDULE_EXACT_ALARM` **solo** si el horario escolar exige minuto exacto; si no → inexact (mejor batería, criterio de Google).
- OEM chinos matan el proceso en background (Xiaomi/Huawei) → pantalla de ayuda con dontkillmyapp.com (ya previsto en plan 04).

## 7. Seguridad / modo padre

- `cryptography` → PIN con hash + salt (plan 05).
- **`local_auth`** (opcional) → huella del adulto como vía rápida al panel; sin biometría obligatoria (gama baja puede no tener lector).
- `flutter_secure_storage` → tokens Supabase.

## 8. Calidad

| Herramienta | Cuándo |
|---|---|
| `flutter test` (unit/widget) | Ola 1+: exigido por el revisor en cada cambio |
| Golden tests | Paleta, contraste AA y Modo calma → atrapa regresiones visuales |
| **`accessibility_tools`** | Solo en dev: verifica targets ≥48dp y semantic labels automáticos — oro puro para una app AAC |
| `patrol` / `integration_test` | Fase 2: flujos nativos (permisos, PIN, notificaciones) |

## 9. Observabilidad (fase 2) — explicado sin jerga

**¿Qué problema tiene?** Cuando la app se cierra sola en el celular de un usuario, nosotros no vemos nada. Para enterarnos y arreglarlo se usan dos caminos:

| Camino | Qué es | Ventaja | Desventaja |
|---|---|---|---|
| **Sentry** | Servicio externo gratuito (5.000 reportes/mes) donde la app envía automáticamente el reporte del cierre inesperado con la línea de código que falló. Se ve en un panel web | Nos enteramos aunque el usuario esté lejos; alertas y trazas | Servicio de terceros (gratis, open source) |
| **Crashlytics** | Igual que Sentry, pero de Google (gratis sin límite) | Gratis y muy integrado con Android | Exige meter **Firebase entero** → tendríamos dos backends (Firebase + Supabase) |
| **Logs locales** | La app escribe sus propios errores en un archivo del propio celular. Nadie nos avisa; hay que pedirle el teléfono al usuario para leerlo | Cero dependencias, cero privacidad en juego | Solo sirve si el usuario nos presta el equipo y nos dice "pasó esto" |

**Postura actual:** el MVP empieza con **logs locales** (el más simple, sin cuentas ni permisos). Al llegar la fase 2 **probamos las dos rutas** (Sentry y Crashlytics) midiendo cuál nos sirve mejor antes de decidir — el usuario quiere testear cada camino, así queda ambas documentadas aquí.

Privacidad: **cero analytics de comportamiento de niños** sin consentimiento explícito del padre. Cualquier reporte de error solo con datos anonimizados.

## 10. CI/CD

- **GitHub Actions**: `flutter analyze` + tests + `appbundle --split-per-abi` en cada tag. Gratis en repo público (minutos ilimitados); privado: 2.000 min/mes.
- **fastlane** (fase 3): subida automática a Play Internal Testing vía Service Account.
- Codemagic como alternativa si Actions se queda corto (free tier limitado, verificar cifra actual).

## 11. Potencial extra — mayor retorno por peso (fase 2+)

1. **`home_widget`**: picto de emergencia / frase del día en la pantalla de inicio del celular → la app a un toque, peso mínimo.
2. **STT on-device** (`sherpa_onnx`): práctica de pronunciación con retroalimentación (§2).
3. **Mascota Rive**: reacciona al completar rutinas (engagement sin sonidos fuertes).
4. **Multi-perfil escolar**: varios niños en un dispositivo (Drift) → uso real en aula.
5. **Reportes locales para padres**: gráficos de uso (`fl_chart` o sparklines propios) — solo agregados, export con consentimiento.
6. **Sync más robusta**: si crece el multi-dispositivo, evaluar **Brick** (recomendado por Supabase) o **PowerSync**. Hoy: cola de sync simple propia (plan 06).

## 12. Descartados (con porqué)

| Descartado | Por qué |
|---|---|
| Redis/Upstash | Decidido: sin Redis (plan 00 §3.2) |
| Hive / Isar originales | Abandonados por su autor; los forks son riesgo asumido, no feature |
| GetX | Crisis de mantenimiento, deuda técnica documentada |
| Firebase completo | Duplica Supabase y añade segundo backend + google-services.json |
| `awesome_notifications` | Incompatible con `flutter_local_notifications`; watermark en FCM gratis |
| ARASAAC | Licencia no-comercial → riesgo en Play |
| Flame por defecto | Peso y complejidad injustificados para los juegos previstos |
| Deferred components | Complejidad > beneficio en APK de este tamaño |

## 13. pubspec candidato (lo que congelará la Ola 1)

```yaml
dependencies:
  flutter_riverpod: ^3.0.0
  go_router: ^16.0.0
  drift: ^2.35.1
  drift_flutter: ^0.2.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  shared_preferences: ^2.5.5
  flutter_secure_storage: ^11.2.0
  flutter_svg: ^2.2.0
  flutter_tts: ^4.2.5
  flutter_local_notifications: ^19.0.0
  timezone: ^0.10.0
  local_auth: ^2.3.0
  cryptography: ^2.7.0
  supabase_flutter: ^2.8.0
  connectivity_plus: ^6.1.0

dev_dependencies:
  flutter_test: any
  flutter_lints: ^6.0.0
  drift_dev: ^2.35.0
  build_runner: ^2.4.0
  accessibility_tools: ^3.0.0
```

> Versiones exactas se resuelven con `flutter pub add` al crear el proyecto (§1 es lo verificado hoy); la lista de paquetes es lo que importa.

## 14. Candidatos de fase 2 — se prueban todos antes de decidir

Postura del usuario: **probar cada camino en la práctica** y decidir midiendo. Quedan documentados aquí como candidatos, no como decisiones tomadas:

1. Observabilidad: logs locales (MVP) vs Sentry vs Crashlytics (§9).
2. STT on-device `sherpa_onnx` (~+40 MB) vs quedarnos solo con TTS.
3. `home_widget` (picto en pantalla de inicio): ¿lo metemos en el MVP o es fase 2?
4. Mascota Rive vs animaciones nativas en las rutinas.
