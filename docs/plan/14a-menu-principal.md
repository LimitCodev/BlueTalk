# Plan 14A — Menú principal animado y cambio de nombre

**Parte de:** `docs/plan/14-menu-mascota-graficos.md` (lee antes su §1–§3).
**Objetivo:** después del nombre, la app abre un **menú de botones grandes y animados**
en lugar de ir directo al tablero de pictogramas, como `/menu` de `bluetalk.lovable.app`.
Además, el adulto puede cambiar el nombre desde el Modo padre.

## 1. Referencia: cómo es el menú de la web

Extraído del bundle desplegado (`/assets/index-4jkF9vaO.js`, componente de `/menu`):

- **Cabecera:** logo, «¡Hola, {nombre}! 👋» y debajo «¿Qué quieres hacer hoy?».
- **Carrusel vertical:** solo se ven 3 tarjetas. La del centro va a escala 1 y opacidad 1. Las vecinas
  van a escala 0,9, opacidad 0,4, un poco desenfocadas y desplazadas ±96 px. La transición dura unos 400 ms.
- **Cómo se mueve:** con un deslizamiento vertical de más de 40 px o la rueda del ratón, con las flechas ▲ ▼
  arriba y abajo, y con unos puntos indicadores a la derecha.
- **Tocar:** la tarjeta del centro abre su sección. Una vecina pasa al centro.
- **Tarjeta:** icono de 64 px en un cuadro de color suave, título grande, descripción corta,
  borde de 2 px del color de la categoría y esquinas de 16 px.
- **Tarjetas de la web:** Categorías, Aprende Jugando, Pictogramas, Anuncios, Mi Horario y Estadísticas.

## 2. Qué se adapta y por qué

| Web | App | Motivo |
|---|---|---|
| Categorías + Pictogramas (2 tarjetas) | **Comunicar** (1 tarjeta) | En la app es una sola sección. |
| Aprende Jugando | **Aprender** | Igual. |
| Mi Horario | **Rutinas** | Incluye horario, primero y luego, y bienestar. |
| Anuncios | — | Sin red (decisión D5). |
| Estadísticas | **Modo padre** | Las estadísticas son del adulto y van protegidas con código. |
| — | **Ajustes** | Voz, colores y modo calma. |
| Desenfoque de vecinas | Solo escala y opacidad | `ImageFiltered` es caro en gama baja. |
| Puntos de 8 px | Puntos dentro de un objetivo táctil de 48 dp | Accesibilidad. |

**Orden fijo** (nunca se reordena ni se recuerda la última posición; siempre empieza en Comunicar):

| # | Título | Descripción | Icono | Color (token existente) | Destino |
|---|---|---|---|---|---|
| 1 | Comunicar | Arma frases con pictogramas | `chat_bubble` | primario | `/home/comunicar` |
| 2 | Aprender | Juegos de memoria, cuentos y dibujo | `menu_book` | verde del logo (acento) | `/home/aprender` |
| 3 | Rutinas | Mi horario y primero y luego | `schedule` | categoría `lugares` | `/home/rutinas` |
| 4 | Ajustes | Voz, colores y modo calma | `settings` | categoría `emociones` | `/home/ajustes` |
| 5 | Modo padre | Solo para adultos, con código | `lock` | categoría `acciones` | `/padre` |

Usa los colores de `context.colores` / `AppColors`. No escribas colores fijos: el menú
debe seguir las 7 paletas y el modo calma.

## 3. Pasos

### A1 — Ruta `/inicio` y arranque

1. `lib/app/router.dart` ya supera el límite (101 líneas, en `_deuda`). **Antes de añadir nada**, parte
   el archivo: mueve las ramas del shell a `lib/app/router_ramas.dart` y baja su número en `_deuda`.
   - Commit: `REFACTOR: ramas del shell en su propio archivo`
2. Añade `GoRoute(path: '/inicio')` fuera del `StatefulShellRoute`, con la misma función `page(...)`
   (respeta el modo calma).
3. `initialLocation`: `hasProfile ? '/inicio' : '/onboarding'`.
4. `onboarding_screen.dart`: `context.go('/inicio')` en lugar de `'/home/comunicar'`.
5. `padre_screen.dart` `_salir()`: ir a `'/inicio'` en lugar de `'/home/ajustes'`.
6. Actualiza `test/core/router_test.dart` (ruta inicial con y sin perfil).
   - Commit: `FEAT: ruta de inicio tras el nombre`

### A2 — Pantalla del menú

Carpeta nueva: `lib/features/inicio/`. Cada archivo tiene 100 líneas o menos.

| Archivo | Contenido |
|---|---|
| `menu_opciones.dart` | Lista `const` de las 5 opciones: id, título, descripción, icono, función de color y ruta. Enum `MenuOpcion` (lo usa la guía en 14B). |
| `inicio_screen.dart` | `Scaffold`: cabecera con saludo y botón de modo calma, y el carrusel. Si `MediaQuery.accessibleNavigationOf(context)` es verdadero, muestra `inicio_lista.dart`. |
| `menu_carrusel.dart` | `PageView` vertical con `PageController(viewportFraction: 0.38)`, más las flechas y los puntos. |
| `menu_tarjeta.dart` | La tarjeta. Recibe `t` (distancia al centro, de 0 a 1) y aplica `Transform.scale(1 - 0.1*t)` y `Opacity(1 - 0.6*t)`. |
| `inicio_lista.dart` | Alternativa sin carrusel: `ListView` con las 5 tarjetas a escala 1, para TalkBack. |

Detalles que deben cumplirse:

1. **Saludo:** «¡Hola, {apodo}! 👋». Si el apodo está vacío («Entrar sin apodo»), dice «¡Hola! 👋».
   Debajo: «¿Qué quieres hacer hoy?».
2. **Animación:** un `AnimatedBuilder` sobre el `PageController` calcula `t = (page - i).abs().clamp(0, 1)`.
   Así la escala y la opacidad siguen al dedo mientras desliza (el «movimiento al scrollear»).
   Al abrir el menú, las tarjetas entran escalonadas: 60 ms entre una y otra, `Curves.easeOutBack`, 350 ms.
3. **Toque:** la tarjeta central hace `context.go(ruta)`. Una vecina hace `animateToPage(i, 300 ms)`.
4. **Flechas ▲ ▼:** `IconButton` de 48 dp, deshabilitados en los extremos y con tooltip «Anterior» / «Siguiente».
5. **Puntos:** 5 puntos, cada uno dentro de un objetivo de 48 dp. El activo es más alto (como en la web).
   La etiqueta `Semantics` dice «Ir a Rutinas, 3 de 5».
6. **Modo calma o sin animaciones:** `jumpToPage` en lugar de `animateToPage`, sin entrada escalonada.
   La escala y la opacidad se mantienen, porque no son movimiento, solo posición.
7. **Semántica:** cada tarjeta es `Semantics(button: true, label: 'Comunicar. Arma frases con pictogramas')`.
8. **Orientación horizontal:** el carrusel tiene una altura máxima. Al girar el teléfono, la tarjeta
   del centro sigue entera (con `LayoutBuilder` y un `SingleChildScrollView` si no cabe).
9. Expón `menuCarruselProvider` (o un `ValueNotifier`) con el índice centrado y un método `centrar(MenuOpcion)`.
   14B lo usa para llevar al centro la tarjeta que explica.
   - Commit: `FEAT: menu principal con carrusel animado como la web`

### A3 — Volver al menú desde las secciones

1. `lib/app/shell.dart`: botón `leading` en la `AppBar` con el icono `home_outlined`, tooltip «Inicio»
   y `context.go('/inicio')`.
2. `lib/app/atras_shell.dart` (`manejarAtras`):
   - Las vistas internas no cambian (juego, Rutinas, categoría, Mis mensajes).
   - `index != 0` → `context.go('/inicio')` (antes `goBranch(0)`).
   - En Comunicar, en su inicio → `context.go('/inicio')` (antes `SystemNavigator.pop()`).
   - `manejarAtras` necesita un `BuildContext` o el `GoRouter`: pásalo como parámetro.
3. En `inicio_screen.dart`, un `PopScope(canPop: false)` que hace `SystemNavigator.pop()` solo si
   `saleConAtrasProvider` es verdadero. Actualiza el comentario del gancho del kiosko.
4. Tests: cada fila de la tabla del plan 14 §2 (busca los tests actuales de Atrás con
   `grep -rn "Atrás\|atras" test/`).
   - Commit: `FIX: Atras de las secciones vuelve al menu principal`

### A4 — Cambiar el nombre desde el Modo padre

1. `profile_controller.dart`: método `renombrar(String nombre)`, que recorta espacios, guarda con
   `profileRepoProvider` y actualiza el estado. Acepta vacío (equivale a «sin apodo»).
   `ChildProfile.copyWith(nickname:)` ya existe.
2. Archivo nuevo `lib/features/padre/control/control_nombre.dart`: un `ListTile` «Nombre del niño o niña»
   con el subtítulo del apodo actual (o «Sin apodo»), que abre un diálogo con un `TextField` de 20 caracteres
   como máximo (mismas reglas que el onboarding), «Guardar» y «Cancelar». El texto de ayuda dice
   «Un apodo basta. Se guarda solo en este teléfono.».
3. Insértalo en `control_screen.dart`, arriba de «Perfil de edad». **Ese archivo está en `_deuda` (199)
   y no puede crecer:** saca otra sección a su propio archivo para compensar.
4. Solo es accesible tras el código: el Modo padre ya lo exige.
5. Tests: renombrar persiste tras recargar el repositorio; nombre vacío; el menú muestra el nombre nuevo.
   - Commit: `FEAT: cambiar el nombre del nino desde el modo padre`

### A5 — Evidencia

`docs/informes/14a-evidencia.md` con capturas del menú en claro, oscuro y calma, y en horizontal,
más la tabla de Atrás comprobada en el emulador. El resultado con TalkBack real queda **NO VERIFICADO**
si no hay teléfono.

## 4. Aceptación

- Instalación limpia: nombre → menú. Segundo arranque: menú directo.
- El carrusel sigue al dedo, las flechas y los puntos funcionan, y la tarjeta central abre su sección.
- Atrás cumple la tabla del plan 14 §2.
- Cambiar el nombre en el Modo padre se ve en el saludo del menú al salir.
- `flutter analyze` con 0 problemas y `flutter test` en verde.
