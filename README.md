# BlueTalk 💙

**Tu voz, siempre contigo.**

Multiplataforma de comunicación aumentativa y alternativa (AAC) para niños autistas: pictogramas con voz, juegos, rutinas diarias, bienestar y modo de acompañamiento para padres.

 APK Android (MVP) construido con **Flutter** — pensado para correr bien en celulares de bajos recursos y funcionar **100% offline**.

## Estado

MVP funcional por etapas; cada etapa cierra con evidencia y revisión en
[`docs/informes/`](docs/informes/):

- Fase 0 y Fase 1 cerradas (`docs/informes/fase0-notas.md`,
  `fase1-evidencia.md`).
- Etapa A (fallos vistos en el teléfono) y Etapa B (marca y colores
  personalizables) del plan 13 cerradas y corregidas por el revisor.
- Gates actuales: `flutter analyze` 0 problemas · `flutter test`
  252/252.

Documentación:

- [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) — decisiones técnicas y diagrama
- [`docs/plan/00-PLAN-MAESTRO.md`](docs/plan/00-PLAN-MAESTRO.md) — plan completo y convenciones
- `docs/plan/01…13` — planes por área (cimientos, AAC, juegos, rutinas/salud, modo padre, Supabase, release, revisión, pulido de uso real)

## Vista previa de pictogramas

Ábrelo en el navegador: [`docs/preview/muestra-pictos.html`](docs/preview/muestra-pictos.html)
(Mulberry Symbols, CC BY-SA 4.0, con la paleta celeste pastel)

## Stack

| Capa | Elección |
|---|---|
| App | Flutter 3.x (Dart) |
| Estado | Riverpod |
| Datos locales | SharedPreferences — offline-first |
| Datos remotos | Supabase/Drift: fuera del MVP hasta nueva decisión |
| Voz | flutter_tts (es-ES, offline) |
| Pictogramas | Mulberry Symbols (CC BY-SA 4.0) + Twemoji |

## Requisitos para compilar

- Flutter SDK (instalado: 3.44.4 stable)
- Android SDK + Java 17 (para compilar el APK)

```bash
flutter pub get
flutter run
```

Para el APK de reparto (release por arquitectura + SHA-256):

```bash
./scripts/build-apk.sh    # sale en dist/BlueTalk.apk
```

Guía de instalación con avisos de Play Protect: [`docs/play/instalar-apk.md`](docs/play/instalar-apk.md).

## Licencia de contenido

- Código: ver `LICENSE`.
- Pictogramas **Mulberry Symbols** © Steve Lee, [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) — créditos en la app.
- Twemoji © Twitter, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

> Proyecto académico. Los datos de personas, colegios y contactos son de demostración; no contienen información real.
