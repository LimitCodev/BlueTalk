# Evidencia 14C — Gráficos del adulto (2026-11-12)

Rama `feat/graficos-padre`. Emulador `bluetalk_gama_baja` (API 28, 720×1280,
280 dpi, 1 GB de RAM, GPU por software `swiftshader_indirect`).

## Commits

| Commit | Qué entrega | Paso del plan |
|---|---|---|
| `8d4e7b1` | Dona y anillo de porcentaje | 1 |
| `8cad74b` | Medidor, línea, calendario y barra apilada | 2 |
| `8fa424b` | Tarjetas con comparación respecto al periodo anterior | 3 |
| `fce3398` | Animación de entrada y toque | 4 |
| `8323101` | Resumen del adulto con gráficos | 5 |
| `7d2c41b` | Informes semanal y mensual con gráficos variados | 6 |
| `3e1065f` | Test de perfilado del informe mensual con 30 días | 7 |
| `9672b67` | Test y driver de capturas | 8 |
| `5feebef` | Arreglo: el medidor no se dibujaba | — |
| `95df126` | Arreglo: las pestañas de Informes no se leían | — |
| este commit | Evidencia y capturas | 8 |

## Defectos encontrados en el emulador y corregidos

1. **El medidor «¿Se comunica más o menos que antes?» no se dibujaba en
   ningún tema.** Su `CustomPaint` no tiene hijo y estaba en una `Column`
   con ancho libre, así que medía 0 de ancho y el pintor salía sin dibujar.
   El test que había solo comprobaba el ángulo de la aguja. Arreglo:
   `size: Size.infinite`. Test nuevo «el medidor ocupa el ancho de su
   tarjeta»: falla sin el arreglo y pasa con él.
2. **Las pestañas «Semanal / Mensual» no se leían.** Usaban los colores por
   defecto de Material 3 (`primary`), pensados para fondo claro, sobre la
   barra azul: la elegida se perdía en claro y desaparecía en oscuro. Ahora
   usan `onHeader`, el color del título de la barra. Se cambió en
   `informes_screen.dart` y no en el tema, porque `app_theme.dart` está en la
   deuda del trinquete (213 líneas) y no puede crecer. Es el único `TabBar`
   de la app. Test nuevo «las pestañas se leen sobre la barra de color».
3. **El test de capturas mentía en «sin datos».** Al volver a montar el
   `ProviderScope` sin clave nueva, Flutter reutilizaba el estado anterior, y
   `14c-vacio.png` salía con los datos llenos. Ahora cada captura usa
   `key: UniqueKey()`.

## Capturas

`integration_test/capturas_graficos_test.dart`, con
`test_driver/capturas_driver.dart`:

| Archivo | Qué muestra |
|---|---|
| `capturas/14c-claro.png` | Semanal, tema celeste: tarjetas con comparación |
| `capturas/14c-vacio.png` | Semanal sin datos: ceros e «Igual que la semana pasada» |
| `capturas/14c-calma.png` | Tema gris con modo calma: medidor y columnas |
| `capturas/14c-oscuro.png` | Mensual, tema oscuro: calendario y dona |

**Aviso sobre `14c-oscuro.png`:** la dona sale como un anillo gris, sin
sectores. No es un fallo de la app. En el mismo momento del test, el pintor
de la dona tiene `progreso=1.0`, 5 sectores y sus colores (comprobado con un
`debugPrint` temporal en el emulador), y la misma pantalla dibujada en el
host sí muestra los sectores. Lo que no se refresca es la imagen de esa capa
en el modo de captura del test (`convertFlutterSurfaceToImage`).

La cruz verde de `14c-calma.png` es la marca del toque que dibuja el test al
desplazar la lista, no forma parte de la app.

## Rendimiento (paso 7): NO CUMPLE en el emulador

```bash
flutter drive --profile --no-dds --driver=test_driver/perf_driver.dart \
  --target=integration_test/perfilado_informes_test.dart
```

`--no-dds` es necesario: sin él, `traceAction` no puede conectarse al VM
Service.

| Medida (30 fotogramas, informe mensual con 30 días) | Valor |
|---|---|
| Fotograma medio total | **39,4 ms** |
| Construcción media | 2,8 ms |
| Pintado medio | 19,0 ms |
| Objetivo del plan | ≤ 16 ms |

La construcción va sobrada; el coste está en el pintado. El emulador pinta
por software, así que en un teléfono real debería ser bastante menor, pero
con esta medida **no se puede dar por cumplido**. Se midió una sola vez.

**Decisión del dueño:** medir en un teléfono real antes de optimizar, u
optimizar ya el pintado (por ejemplo, la dona y el calendario).
No se anota en `decisiones-pendientes.md` para no chocar con la rama
`feat/menu-guia`, que también añade texto al final de ese archivo.

## Aceptación

| Criterio | Estado |
|---|---|
| Cada gráfico tiene su pregunta, su número grande y su frase | ✅ capturas y tests |
| Sin datos sale el texto amable | ✅ `14c-vacio.png` y tests |
| Las animaciones se apagan con el modo calma | ✅ tests de `AnimacionGrafico` |
| La dona suma 100 %, el anillo no pasa de 100 % y no hay división entre 0 | ✅ tests de geometría |
| `flutter analyze` con 0 problemas y `flutter test` en verde | ✅ 435/435 |
| Fotograma medio ≤ 16 ms con 30 días | ❌ 39,4 ms en el emulador |

## NO VERIFICADO

- El rendimiento en un teléfono real, con GPU.
- Que el dueño entienda los gráficos «sin leer nada» (plan 14C §6).
- TalkBack real sobre los gráficos.
