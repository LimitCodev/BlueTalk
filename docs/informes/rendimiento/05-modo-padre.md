# Rendimiento — modo padre

Archivos: `lib/features/padre/`. El adulto entra poco, pero cuando entra
quiere datos frescos y gráficos fluidos; el coste no debe recaer en el niño.

## PERF-PAD-01 · El panel puede enseñar métricas de antes (P1, correctitud)

**Dónde**
`lib/features/padre/dashboard/metricas.dart:60` (`metricasProvider`) y
`lib/features/padre/diagnostico/observaciones.dart:176`
(`observacionesProvider`) son `FutureProvider` **sin** `autoDispose`.
Nadie los invalida al entrar en el panel: solo hay un `invalidate` manual en
el botón “Reintentar” de `resumen_screen.dart:34`.

**Qué pasa**
El adulto entra, ve el resumen, sale, el niño usa la app un rato y el adulto
vuelve a entrar: los números y las observaciones siguen siendo los de la
primera entrada. `informeProvider` sí es `autoDispose`, así que los informes
se recalculan; el resumen no.

**Arreglo pequeño**
- Hacer `autoDispose` ambos providers (se recalculan al montar el resumen) o
  invalidarlos en `PadreController.entrar()` y al cambiar a
  `PadreVista.resumen`.
- Cuidado: `metricasProvider` también lo usa el propio resumen; `autoDispose`
  no cambia el contrato.
- Añadir un test: registrar un evento entre dos montajes y comprobar que el
  segundo resumen lo refleja.

**Riesgo** bajo.

---

## PERF-PAD-02 · Abrir Informes vuelve a consultar hasta 9 días de Android (P1)

**Dónde** `lib/features/padre/informes/captura_apps.dart` y
`informes_providers.dart:14`.

`informeProvider` es `autoDispose`; cada vez que se abre la pestaña Semanal o
Mensual (y al cambiar entre ellas) se ejecuta `capturarUsoApps`:
- Hoy y ayer se releen **siempre**: 2 consultas nativas + 2 guardados.
- Los 7 días anteriores solo si no tenían datos, pero la comprobación recorre
  la lista.

En el primer uso puede haber 9 consultas nativas seguidas antes de pintar el
informe. En un equipo lento eso se nota como “Informes tarda en abrir”.

**Arreglo pequeño**
- Guardar `bluetalk_uso_apps_ultima_captura` (epoch) y no repetir la captura
  si pasaron menos de 5–10 minutos. El detalle de hoy puede esperar.
- Ejecutar la captura después del primer frame (`addPostFrameCallback` o un
  provider aparte que no bloquee el informe) y refrescar cuando termine.
- Mantener la regla actual: sin permiso no se lee nada.

**Cómo comprobarlo**
Abrir/cerrar Informes dos veces seguidas y contar llamadas al gateway con un
doble de prueba; la segunda debe ser 0.

**Riesgo** bajo.

---

## PERF-PAD-03 · El informe reparsea el catálogo y espera en serie (P1, ver núcleo)

**Dónde** `informes_providers.dart:27-31`.

Para construir el mapa de nombres recorre las categorías y hace
`await pictos.pictogramsOf(c.id)` **en serie**, y cada llamada reparsea los
234 pictos. Son 7 viajes al `SeedStore` y ~1 600 objetos por informe.

**Arreglo pequeño**
Con el caché de PERF-CORE-03 basta cambiar el bucle por una sola lectura de
todos los pictos. Si se mantiene la API, usar `Future.wait` para las 7
categorías. El mapa de nombres se puede cachear en un provider que dependa
solo del catálogo.

---

## PERF-PAD-04 · Los gráficos animan 600 ms todos a la vez (P1, a confirmar)

**Dónde** `informes/animacion.dart` y las secciones de `informeVista.dart`.
La medición de 14C dio **39,4 ms de media** (paint 19,0 ms) en el informe
mensual del emulador, muy por encima de 16 ms.

Hipótesis, por orden:
1. Varias gráficas visibles arrancan su `TweenAnimationBuilder` de 600 ms en
   el mismo frame; cada frame reconstruye y repinta cada `CustomPaint`.
2. Las tarjetas con sombra/elevación se repintan alrededor de cada gráfico.
3. El `ListView` construye todas las secciones (aunque solo monta las
   visibles), incluidas las que están fuera de pantalla.

**Qué hacer antes de tocar**
Perfilar el informe mensual en perfil y mirar el timeline: ¿el pico está en
los 600 ms de entrada o se mantiene al hacer scroll? Sin eso, cualquier
cambio es a ciegas.

**Arreglos candidatos (S/M)**
- Animar solo la primera gráfica o escalonar la entrada (0, 60, 120 ms).
- Bajar la duración a 300 ms en informes largos.
- Mantener `RepaintBoundary` por gráfico (ya está) y añadir uno por tarjeta.
- Cambiar `ListView(children:)` por `ListView.builder` si el perfil muestra
  coste de construcción; el delegado actual ya es perezoso en montaje, así
  que medir antes.

**Riesgo** bajo en lo visual; el modo calma ya desactiva la animación.

---

## PERF-PAD-05 · Guardar el filtro web escribe 10 claves en serie (P2)

**Dónde** `filtro_web_controller.dart:88-102`.

Cada cambio de interruptor guarda 6 booleanos + 4 JSON con `await` uno detrás
de otro, y además actualiza la copia nativa. En un equipo lento, tocar tres
interruptores seguidos encadena 30 escrituras.

**Arreglo pequeño**
- `Future.wait` para las claves independientes.
- O una sola clave JSON `padre_filtro_web` con el objeto completo; migrar
  leyendo el formato viejo una vez y borrando las claves sueltas.
- No bloquear la UI: el estado ya es optimista (`state = next` antes de
  guardar).

**Riesgo** medio por la migración; hacerlo con test de lectura del formato
viejo.

---

## PERF-PAD-06 · `metricasProvider` recorre los eventos 8 veces (P2)

**Dónde** `metricas.dart:79-96`.

El bucle principal ya hace una pasada, pero `eventosPorDia` hace
`eventos.where(...)` una vez por cada uno de los 7 días. Con ≤ 500 eventos son
3 500 comparaciones; irrelevante hoy. Si se quiere dejar limpio, contar en un
`Map<String,int>` por `claveDia` en la misma pasada.

---

## Lo que ya está bien en el modo padre

- El PIN se deriva en isolate (`pin_store.dart`); el gate no congela la UI.
- Las pantallas del adulto son navegación interna sin rutas nuevas; no
  reconstruyen el router raíz.
- `informeProvider` es `autoDispose`: el informe no se queda viejo.
- Los gráficos respetan “quitar animaciones” y modo calma.
- El uso de otras apps se lee solo si el permiso está concedido y solo en la
  edición directa (`edicionDirectaProvider`).
- El filtro web no hace polling: el estado de la VPN se consulta al entrar.
- Las observaciones son deterministas y con disclaimer siempre visible.

## Prueba manual sugerida

1. Entrar al panel, anotar “pictos hoy”; salir, tocar 3 pictos, volver a
   entrar: el número debe subir.
2. Abrir Informes dos veces seguidas y cronometrar la segunda.
3. Activar modo calma y abrir el informe mensual: sin animación de entrada.
4. Guardar un dominio en el filtro y comprobar que el interruptor responde
   al instante aunque el guardado tarde.
