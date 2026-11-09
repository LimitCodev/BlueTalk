# P0-4 — Permisos opcionales y panel accesible (2026-11-08)

Rama `feat/modular-freemium-aws`. Base `c71687d`.

## Qué se corrigió

`requisitosPlayStore.md` marca como **P0-4** que el asistente de permisos
bloqueaba el panel del adulto. Play lo considera coerción: el comunicador
funciona sin avisos, sin acceso al uso y sin VPN, así que ningún permiso
puede ser obligatorio para entrar.

| Antes | Después |
|---|---|
| `avisos`, `uso` y `vpn` con `requerido: true` | Los tres con `requerido: false` |
| `PadreScreen` cambiaba el panel por el asistente si faltaba un «requerido» | El panel se muestra siempre tras aceptar la legal |
| El asistente decía «Todavía no se puede avanzar» en rojo | Tarjeta neutra: «Ninguno de estos permisos es obligatorio» |
| No había salida explícita | Botón persistente «Continuar sin estos permisos» |
| El acceso a la política dependía del PIN | Ya estaba resuelto en `103aa3f`: Ajustes › Legal abre los textos sin PIN |

## Archivos tocados

- `lib/features/padre/permisos/permisos_controller.dart` — los cinco
  permisos quedan como opcionales; el diagnóstico sigue mostrando el estado
  real de Android.
- `lib/features/padre/permisos/permisos_asistente_screen.dart` — se quitó
  el modo «paso obligatorio», la tarjeta roja y el bloqueo; se añadió la
  tarjeta informativa y el botón de continuar.
- `lib/features/padre/permisos/permiso_model.dart` — comentarios alineados
  con P0-4; `faltanRequeridos` se conserva para permisos futuros, pero la
  lista de producción no marca ninguno.
- `lib/features/padre/padre_screen.dart` — el panel ya no depende de
  `faltanRequeridos`; se mantiene la relectura de permisos al entrar y al
  volver del sistema para que el asistente no enseñe datos viejos.
- `lib/features/padre/control/control_screen.dart` — el enlace «Revisar
  los permisos» dice explícitamente que se puede continuar sin ellos.
- `test/padre/permisos_test.dart` — pruebas nuevas y actualizadas.
- `test/core/accessibility_helper.dart` — el helper acepta el tema real
  para auditar contraste, no solo targets táctiles.
- `test/arquitectura/tamano_test.dart` — trinquete bajado a los conteos
  nuevos (`padre_screen` 168, `permiso_model` 107, asistente 179).
- `docs/informes/informes-optimizacion-estado.md` — se marca P0-4 como
  hecho en la lista de pendientes de la ronda anterior.

## Verificación

| Comando | Resultado |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test test/padre/permisos_test.dart` | **17/17** |
| `flutter test test/padre/` | **168/168** |
| `flutter test` | **384/384** |
| `flutter test test/arquitectura/tamano_test.dart` | **2/2**, sin subir topes |

Pruebas nuevas o reescritas:

- Con **todos** los permisos denegados (avisos, uso y batería), el panel
  abre y muestra «Uso del día». (El administrador se retiró después, en
  P0-3.)
- Con el **filtro activo y la VPN denegada**, el panel también abre; la
  VPN queda como permiso pendiente sin cerrar nada.
- Revocar un permiso fuera de la app y volver **no** cierra el panel.
- Ningún permiso de producción queda con `requerido: true`; un test lo
  bloquea para que no vuelva el muro por descuido.
- El botón «Continuar sin estos permisos» cierra el asistente; con todo
  concedido pasa a decir «Volver al panel».
- El asistente pasa la auditoría de accesibilidad **con el tema real**
  (`buildBlueTalkTheme(AppColors.celeste)`), no con el tema por defecto.

## Revisión independiente

El subagente `revisor` revisó el módulo (`docs/informes/p0-4-revisor.md`):
**0 bloqueantes, 0 graves, 5 menores y 4 sugerencias**. Se corrigieron los
cinco menores:

1. La tarjeta informativa ahora usa `surface` con borde `outlineVariant`
   (antes se confundía con el fondo del Scaffold).
2. Un permiso opcional pendiente ya no usa icono de error ni chip rojo;
   usa información y borde neutro.
3. El comentario obsoleto de `PadreScreen` se actualizó.
4. Se añadió la prueba del panel con el filtro activo y la VPN denegada.
5. La nota de estado en `informes-optimizacion-estado.md` queda declarada
   en «Archivos tocados».

También se aplicaron las sugerencias 6–8 (asegurar cero peticiones, bajar
el trinquete y cambiar el texto del botón cuando no hay pendientes). La
sugerencia 9 se resolvió con el enlace único al asistente: ya tiene una
fila por permiso con activación, y duplicar tarjetas en Control habría
hecho crecer un archivo que está en el trinquete.

## Criterios de aceptación del documento

- [x] Se puede entrar al panel del adulto con todos los permisos denegados.
- [x] No hay ningún texto que diga que un permiso no crítico es obligatorio.
- [x] Los permisos se piden en contexto, con explicación y alternativa.
- [x] La política y los términos se leen sin PIN desde Ajustes.
- [ ] Prueba en teléfono físico: **NO VERIFICADA** (no hay dispositivo
  conectado en esta sesión).

## Lo que sigue en `requisitosPlayStore.md`

- **P0-2 VPN**: sigue dependiendo de la ruta A/B del dueño.
- **P0-3 admin**: el receptor sigue en el manifiesto; Play lo prohíbe y hay
  que quitarlo en cualquier ruta.
- **P0-1 keystore**, **P0-5 identidad/correo/URL** y **P0-8 cuenta y
  testers**: decisiones del dueño.
- **P0-6 ficha y assets**: pendiente.
