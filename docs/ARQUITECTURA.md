# BlueTalk — Arquitectura

**Multiplataforma de comunicación aumentativa y alternativa (AAC) para niños autistas.**
APK Android (MVP) construido en Flutter, con base de datos local offline-first y Supabase free opcional.

## Diagrama de decisiones

```
                        ┌─────────────────────────────┐
                        │   APP FLUTTER (Dart)        │
                        │   AOT nativo → gama baja    │
                        └──────────────┬──────────────┘
                                       │
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
   ┌──────────▼──────────┐  ┌──────────▼──────────┐  ┌──────────▼──────────┐
   │  UI (Riverpod)      │  │  Núcleo (go_router) │  │  Modo calma         │
   │  rebuilds granulares│  │  shell fijo, predec.│  │  grises + sin anim. │
   └──────────┬──────────┘  └─────────────────────┘  └─────────────────────┘
              │
   ┌──────────▼──────────────────────────────────────────────┐
   │          CAPA DE DATOS (contratos / repositorios)        │
   ├─────────────────────────────┬───────────────────────────┤
   │  LOCAL (fuente de verdad)   │  REMOTO (flag, opcional)  │
   │  Drift/SQLite + seeds mock  │  Supabase free            │
   │  100% offline, $0           │  RLS por auth.uid + sync  │
   └─────────────────────────────┴───────────────────────────┘
```

## Decisiones técnicas y su porqué

| Decisión | Por qué | Descartado |
|---|---|---|
| **Flutter (Dart)** | AOT nativo, buen rendimiento en dispositivos de 1–2 GB RAM, un código → Android/iOS | React Native (puente JS, más lento en gama baja), Kotlin puro (solo Android, más lento de desarrollar) |
| **Drift (SQLite) local-first** | El niño en el aula no tiene red: la app debe funcionar 100% offline. Supabase solo sincroniza | Depender de la red para el flujo principal |
| **Supabase free** | Auth + Postgres + RLS sin costo. Decisión del usuario | Neon (sin auth integrado) |
| **Sin Redis** | Poco tráfico sincronizado → PostgREST + Drift bastan. Redis = complejidad sin beneficio. Si hay Edge Functions con tráfico: Upstash free | Upstash desde el día 1 |
| **Mulberry Symbols (CC BY-SA)** | Licencia comercial libre, SVG, hecho para AAC → cero riesgo legal en Play Store | ARASAAC (CC BY-NC-SA: no comercial) |
| **Modo calma** | Guías de diseño para autismo: baja sobrecarga sensorial, control del usuario sobre color/movimiento | Paleta fija sin control |
| **Rendimiento** | Impeller (por defecto), imágenes con `cacheWidth`, trabajos pesados en isolates, AAB con split-per-abi | Precarga SkSL (obsoleto), deferred components (no compensa) |

## Paleta celeste pastel

Tokens en `lib/core/theme/` (contraste AA verificado por test):

| Token | Valor | Uso |
|---|---|---|
| `bg` | `#F3FAFF` | Fondo (nunca blanco puro) |
| `surface` | `#FFFFFF` | Tarjetas |
| `primary` | `#7FC9EA` | Botones y acentos |
| `primaryInk` | `#12333B` | Texto sobre primary |
| `text` | `#1F3A44` | Texto principal |

## Seguridad y privacidad (MVP)

- **Cero datos reales:** perfiles con apodo local opcional; colegio/contactos son demo.
- **PIN del modo padre:** hasheado con salt (`cryptography`), lockout por intentos.
- **Sin claves en el repo:** `--dart-define` + `.gitignore`.
- **RLS:** cada fila filtrada por `auth.uid()`.
- **Demostración:** datos mock etiquetados; observaciones con disclaimer de no diagnóstico.

## Commits

Un commit = un cambio coherente, mensaje corto en español: `FEAT: pictogramas offline con barra de frase`. Sin textos generados por IA. Detalle completo en `docs/plan/00-PLAN-MAESTRO.md` §6.
