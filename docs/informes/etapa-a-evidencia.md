# Etapa A — evidencia (EN CURSO)

Plan 13: P1 (Atrás), P2 (Artista), P6.1 (pruebas de nombre y rutinas),
P7 (instalación y APK liviano). **Guardado 2026-10-16 00:57 antes de
apagar el equipo.** Punto de reanudación: «P1 — tests rojos».

## Estado por paso

| Paso | Estado |
|---|---|
| P1 — mapeo y decisión de diseño | HECHO (abajo) |
| P1 — tests de las 5 filas en rojo (verificar causa) | PENDIENTE |
| P1 — implementación (PopScope) + gancho kiosko | PENDIENTE |
| P1 — tests en verde + commits | PENDIENTE |
| P2 — Artista sin desplazamiento (Listener, lienzo Expanded, galería en hoja) | PENDIENTE |
| P6.1 — tests: nombre con teclado, actividad en rutinas, voz | PENDIENTE |
| P7 — instalar-apk.md, hash SHA-256, minify, WebP, informe de tamaños | PENDIENTE |
| Informe final + revisor de la etapa | PENDIENTE |

## P1 — mapeo hecho y decisión de diseño

Estructura real verificada:

- `lib/app/router.dart`: `StatefulShellRoute.indexedStack` con 4 ramas
  (`/home/comunicar`, `/home/aprender` = `JuegosGate(JuegosScreen)`,
  `/home/rutinas`, `/home/ajustes`). `/padre` está **fuera** del shell y
  se entra con `context.go('/padre')` desde Ajustes → «Zona de adultos».
- Vistas internas de Aprender: **estado**, no rutas
  (`juegosProvider`: inicio/memoria/cuentos/artista). El doc de
  `JuegosScreen` dice explícitamente «sin rutas propias, para no
  acoplarse al router raíz». `CabeceraJuego` («Volver») llama
  `irAlInicio()`, que además registra `juego_fin` con duración y
  alimenta el dashboard del padre.
- Padre: `PadreScreen` con vistas internas (`padreProvider`:
  legal/gate/resumen/control/salud) como pestañas. Subpantallas:
  `RecuperarScreen` (`Navigator.push`) y `CambiarCodigoDialogo`
  (`showDialog`): **ambas ya se cierran solas con Atrás** (filas 4–5).
- Causa confirmada: **no hay ningún `PopScope` en la app** → Atrás en
  cualquier rama del shell saca la app (lo que el dueño reportó).

**Decisión (el plan P1 paso 1 permite `PopScope` si convertir a rutas
es muy grande):** NO convertir juegos a rutas de go_router; usar un
único `PopScope` en `AppShell` (+ uno en `PadreScreen`). Motivo: la
navegación por estado es deliberada (desacople) y `juegosProvider`
mantiene el registro de sesiones que alimenta el panel del padre;
convertir a rutas obligaría a rehacer ese registro y todos los tests
de juegos — riesgo alto sin ganancia para el usuario.

Diseño a implementar:

1. `AppShell`: `PopScope(canPop: false)` que decide en orden:
   (a) rama Aprender y `juegosProvider != inicio` → `irAlInicio()`;
   (b) rama ≠ 0 → `shell.goBranch(0)`; (c) rama 0 → si
   `saleConAtras` → `SystemNavigator.pop()`, si no, no hace nada.
2. `saleConAtrasProvider` (bool, por defecto true) en `shell.dart`:
   el gancho que el plan 12 F3 activará en el modo kiosko (P1.3).
3. `PadreScreen`: `PopScope` → `_salir()` (cierra sesión y
   `go('/home/ajustes')`), coherente con el botón «Salir».
4. Tests en `test/core/router_test.dart` (harness `_pumpApp` ya
   existente) con `tester.binding.handlePopRoute()`: una fila de la
   tabla por test + fila kiosko. **Primero en rojo** (verificar la
   causa, como pide el plan), luego implementar y pasar a verde.

Commits previstos: `FEAT: atras navega dentro de la app` (paso 1+2+3
del plan) y `TEST: atras en las cinco filas del plan 13`.

## Datos de entrada del usuario

- **Logo (Etapa B/P3):** confirmado por el usuario 2026-10-16 —
  «burbuja de chat **celeste con carita sonriente**», coincide con el
  material del plan 13 (`referencia_logo_y_colores_iniciales.jpeg` en
  la raíz: burbuja celeste sonriente + corazón verde + «BlueTalk»).
- **P.S. del usuario:** el APK **sí funciona en su móvil**, pero
  siguen las dudas con los avisos de instalación → corresponde a P7.1
  (texto corto de instalación, hash SHA-256, enlace de descarga; el
  aviso solo lo elimina Play Store, decisión del dueño ya anotada en
  `decisiones-pendientes.md`).

## Commits de la etapa

- `DOCS: etapa A en curso, mapa del atras listo` (este informe).
- (los de código irán apareciendo aquí al cerrar cada paso)

## NO VERIFICADO

- Todas las filas de Atrás «en el teléfono real»: el dueño debe
  probarlas en su dispositivo (los tests cubren el comportamiento en
  widget). Se añadirá al cierre de la etapa junto con P2/P6.1/P7.
