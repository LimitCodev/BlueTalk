# Informe — revisor — P0-4 permisos opcionales — 2026-11-08

Veredicto: **CORRECCIONES** — sin BLOQUEANTE ni GRAVE; 5 MENOR y 4 SUGERENCIA.

Alcance: cambios **sin commitear** sobre `c71687d` en `feat/modular-freemium-aws`.
No hay commits de la entrega que revisar: no se puede verificar la convención
de mensajes ni «1 cambio por commit». El dueño debe commitear, e incluir la
evidencia `docs/informes/p0-4-permisos-opcionales.md`, que está sin trackear.

## Verificación ejecutada (no se confió en el informe del agente)

| Comando | Resultado real |
|---|---|
| `flutter analyze` | `No issues found!` (14,9 s) |
| `flutter test test/padre/permisos_test.dart` | **16/16** |
| `flutter test test/padre/` | **167/167** |
| `flutter test` | **383/383** |
| `flutter test test/arquitectura/` | **4/4** (incluye `tamano_test.dart` 2/2) |
| `git diff --check` | limpio |
| `pubspec.yaml` | sin tocar |
| Texto de IA / `Co-Authored-By` en el diff | no aparece |
| `print()` / `TODO` / `FIXME` en lo tocado | no aparece |

El objetivo principal **se cumple**: ningún permiso de producción queda con
`requerido: true` (`permisos_controller.dart:59,73,84,100,114`), el panel ya no
lee `faltanRequeridos` (`padre_screen.dart:103-149`) y la política sigue
accesible sin PIN desde Ajustes (`ajustes_info.dart:31-69`, test
`test/features/ajustes_test.dart:171`). La prueba en teléfono físico está
declarada como **NO VERIFICADA** (`p0-4-permisos-opcionales.md:64-65`), que es
lo correcto.

## BLOQUEANTE (BLOCKER)

Ninguno.

## GRAVE (MAJOR)

Ninguno.

## MENOR (MINOR)

1. **[`lib/features/padre/permisos/permisos_asistente_screen.dart:104`]** La
   tarjeta neutra usa `colorScheme.surfaceContainerHighest`, pero el tema lo
   mapea a `paleta.bg` (`lib/core/theme/app_theme.dart:27`) y el Scaffold usa
   ese mismo color de fondo (`app_theme.dart:80`). La tarjeta no tiene borde ni
   sombra: en la app real se ve como texto suelto, no como tarjeta. El test de
   accesibilidad (`test/padre/permisos_test.dart:404-411`) no lo detecta porque
   monta un `MaterialApp` sin `buildBlueTalkTheme`. → Usar `colorScheme.surface`
   (blanco) con `BorderSide(color: colorScheme.outlineVariant)`, o
   `surfaceContainerHigh`; y montar el test con el tema real.

2. **[`lib/features/padre/permisos/permisos_asistente_screen.dart:130,151-163`]**
   Un permiso **opcional** pendiente sigue mostrando `Icons.error_outline` y el
   chip rojo `colorScheme.error`/`onError` con «Falta concederlo · opcional».
   La tarjeta dice que ninguno es obligatorio, pero la fila sigue pareciendo un
   error/alarma para algo que el adulto decidió no conceder; en una app para
   autismo eso es coerción residual. → Usar un icono informativo
   (`Icons.info_outline` o `Icons.radio_button_unchecked`) y un chip neutro
   (`surfaceContainerHigh` + `outline`) con «Opcional, sin conceder»; reservar
   el rojo para fallos reales («No se pudo comprobar»).

3. **[`lib/features/padre/padre_screen.dart:63-65`]** Comentario obsoleto: dice
   que sin refrescar «el panel admitiría un estado antiguo […] no desbloqueaba
   el paso». El panel ya no lee `permisosProvider`; la invalidación solo
   mantiene fresco el diagnóstico del asistente. → Actualizar el comentario (o
   mover la invalidación a `PermisosAsistenteScreen`/`ControlScreen`, que es
   quien la usa).

4. **[`docs/informes/p0-4-permisos-opcionales.md:50-51`]** La evidencia afirma
   que el panel abre con «todos los permisos denegados (avisos, uso y
   administrador; VPN pendiente con el filtro activo)». El test del panel
   (`test/padre/permisos_test.dart:431-452`) deja el filtro apagado, así que la
   VPN no entra en la lista; el caso VPN pendiente solo se prueba a nivel de
   `permisosProvider` (`:536-562`), no con el panel abierto. El código no
   depende de la VPN y el comportamiento es correcto, pero la evidencia declara
   como ejecutado un caso que no lo está. → Activar el filtro en el test del
   panel (override de `filtroWebGatewayProvider` con `activo: true,
   comprobado: true` y `padre_filtro_web_activo`) o separar las dos pruebas en
   la evidencia.

5. **[`docs/informes/informes-optimizacion-estado.md:34`]** La entrega modifica
   un informe de estado dentro de `docs/informes/` (ruta del revisor según plan
   00 §8/plan 08) fuera de su archivo de evidencia, y no lo lista en «Archivos
   tocados» (`p0-4-permisos-opcionales.md:20-36`). El contenido es correcto,
   pero es un cambio no declarado en carpeta ajena. → Mover la nota a la
   evidencia o dejar que el revisor actualice el estado. Aplicando el plan 08 al
   pie de la letra sería BLOCKER de proceso; al ser solo documentación y
   correcta, lo dejo en MENOR.

## SUGERENCIA

6. **[`test/padre/permisos_test.dart:325-336`]** El test «con todo concedido ya
   no se pide nada» no comprueba `peticiones == 0`: solo mira que aparezca
   «Concedido». El nombre promete más de lo que verifica. → Conservar la
   referencia a `_PermisosFalsos` y afirmar `falso.peticiones == 0` (y
   `find.textContaining('Falta concederlo')` vacío).

7. **[`test/arquitectura/tamano_test.dart:50,52,53`]** El trinquete no se relajó
   (bien), pero los archivos encogieron y la deuda no bajó: `padre_screen.dart`
   174→168, `permiso_model.dart` 108→107, `permisos_asistente_screen.dart`
   182→174. El plan pide «al partir uno, baja su número». → Bajar las tres
   entradas a los conteos nuevos.

8. **[`lib/features/padre/permisos/permisos_asistente_screen.dart:73`]** El
   botón dice siempre «Continuar sin estos permisos», incluso con todo concedido
   o si el adulto abrió el asistente solo a revisar. → Usar «Volver al panel»
   cuando `estado.pendientes.isEmpty`, o un «Continuar» neutro.

9. **[`requisitosPlayStore.md:634`]** P0-4 pedía «tarjetas informativas en el
   panel del adulto, con un botón para activar». El panel solo tiene el enlace
   genérico «Revisar los permisos» (`control_screen.dart:134-144`), el
   `ProteccionTile` del admin y el acceso a uso/filtro; no hay tarjeta
   proactiva para avisos ni VPN. El criterio de aceptación se cumple, pero la
   corrección prescrita queda a medias. → Añadir una tarjeta neutra de resumen
   con los pendientes y un botón «Activar», o dejar escrito en la evidencia que
   se optó por el enlace único.

## Resumen para el dueño

- Lo importante está bien: **no hay ningún camino por el que avisos, uso, VPN,
  batería o admin bloqueen el panel o la política**; el botón de continuar está
  en `bottomNavigationBar` con `SafeArea` y target de 48 dp
  (`app_theme.dart:155-165`), y no puede quedar fuera de pantalla.
- Atrás y modo calma no tienen regresión: el asistente es una ruta empujada
  (Atrás la cierra) y el `PopScope` del panel sigue igual; no hay animaciones ni
  audio nuevos.
- Antes de dar la entrega por cerrada: corregir 1–5 (commits `FIX:`) y, si se
  quiere, 6–9. La evidencia debe commitearse; ahora está sin trackear.
