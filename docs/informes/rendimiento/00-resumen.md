# Auditoría de rendimiento — resumen

> **Actualización 2026-11-18:** el estado por módulos, con lo ya corregido en el árbol y lo que sigue abierto, está en `docs/informes/rendimiento-por-modulos-2026-11-18.md`.

Fecha: 2026-11-16 · Base: `8ccbcd6` + arreglo local del menú.
Emulador de referencia: API 28 x86_64, 720×1280 (360×640 dp), Flutter 3.44.4.

## Para qué sirve esto

Rendimiento “pies a cabeza” significa recorrer los flujos reales y anotar
dónde se gasta CPU, memoria o disco sin que el niño o el adulto lo noten.
No es una lista de deseos: cada hallazgo dice **dónde**, **cuánto duele**,
**qué arreglo pequeño lo mejora** y **cómo comprobarlo**.

La auditoría es de lectura de código y de flujo. No inventa mediciones: lo
único medido antes es el informe mensual de 14C (39,4 ms de fotograma medio,
por encima de los 16 ms, en emulador con SwiftShader). Los demás costes se
marcan como **estimados** y se confirman con el perfilador.

## Cómo se prioriza

| Nivel | Significado | Cuándo |
|---|---|---|
| P0 | Se nota en el uso normal o pierde datos | Antes del próximo APK de prueba |
| P1 | Gasto medible en flujos frecuentes | Al tocar ese módulo |
| P2 | Oportunidad, sin prisa | Cuando haya tiempo o se reescriba |

Esfuerzo: **S** < 1 h · **M** media jornada · **L** requiere diseño o
dependencia nueva.

## Los diez arreglos que más rinden

| # | Hallazgo | Dónde | Nivel | Esfuerzo |
|---|---|---|---|---|
| 1 | Cada toque de picto escribe **dos JSON completos** en `SharedPreferences` | `repo_uso.dart`, `resumenes_repo.dart`, `usage_repo_con_resumen.dart` | P0 | M |
| 2 | Los sliders de Ajustes guardan y reconstruyen toda la app en cada tick | `settings_controller.dart`, `app.dart` | P0 | S |
| 3 | El catálogo vuelve a parsear los 234 pictos una vez por categoría | `repo_contenido_seed.dart`, `comunicador_catalog.dart`, `informes_providers.dart` | P1 | S |
| 4 | Cada picto tocado reaplica velocidad y tono al TTS (2 llamadas nativas) | `speak_action.dart`, `tts_service.dart` | P1 | S |
| 5 | El trazo del artista copia la lista y cuenta puntos en cada movimiento (O(n²)) | `artista_controller.dart` | P1 | M |
| 6 | La guía recompone un `Path` de pantalla completa en cada fotograma | `guia_fondo.dart` | P1 | S |
| 7 | Abrir Informes vuelve a consultar hasta 9 días de uso de Android | `captura_apps.dart`, `informes_providers.dart` | P1 | S |
| 8 | El menú de inicio agenda la guía en cada rebuild | `inicio_screen.dart` | P1 | S |
| 9 | El panel del adulto puede mostrar métricas viejas (caché sin invalidar) | `metricas.dart`, `observaciones.dart` | P1 | S |
| 10 | Guardar un dibujo codifica la galería entera en el hilo de UI | `artista_dibujos.dart` | P2 | M |

## Lo que ya está bien (no tocar)

- El PIN se deriva con PBKDF2 en un isolate (`pin_store.dart`); no congela la UI.
- Las rejillas de pictogramas son perezosas (`GridView.builder`,
  `ListView.builder`); no se construyen 234 tarjetas de golpe.
- El artista separa trazo terminado y trazo activo con `RepaintBoundary`
  (`artista_lienzo.dart`): arrastrar no repinta la galería de trazos.
- Los gráficos del adulto también van envueltos en `RepaintBoundary`
  (`grafica_columnas.dart`) y respetan “quitar animaciones”.
- `SeedStore` cachea los JSON de `assets/seed/`; no se leen en cada pantalla.
- `main()` limita la caché de imágenes a 20 MB en equipos con ≤ 3 GB de RAM.
- La retención de eventos está acotada (300 toques, 14 días; 13 meses de
  resúmenes): el almacenamiento no crece sin fin.
- No hay red, ni analítica, ni timers periódicos en segundo plano.

## Qué no se ha medido y hay que medir

1. Perfilado real en un teléfono de gama baja (`flutter run --profile` +
   DevTools > Performance). El emulador x86 con SwiftShader no representa al
   equipo objetivo.
2. Tiempo de arranque en frío (primer frame) con 0 y con 300 eventos.
3. Memoria del catálogo completo de SVG y de la galería de dibujos al límite
   (30 dibujos × 3 000 puntos).
4. Fotogramas del informe mensual tras los arreglos 3, 7 y 10.

## Orden recomendado

1. **P0 de almacenamiento y sliders** (1 y 2): son los que el niño provoca
   sin querer y los que más se notan en gama baja.
2. **P1 baratos** (3, 4, 6, 8): cambios pequeños, sin tocar contratos.
3. **P1 con diseño** (5, 7, 9): el artista necesita cambiar el estado; los
   informes necesitan una regla de caducidad; el panel necesita invalidación.
4. **P2** al tocar cada archivo; no justifican una tanda propia.

## Documentos por módulo

- `01-nucleo-arranque-almacen.md`
- `02-comunicador.md`
- `03-juegos.md`
- `04-rutinas-salud-entorno.md`
- `05-modo-padre.md`
- `06-inicio-guia.md`
- `07-android-release.md`

La auditoría de botones repetidos vive aparte:
`docs/informes/redundancias/`.
