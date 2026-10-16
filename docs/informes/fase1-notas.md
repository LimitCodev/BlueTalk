# Fase 1 — notas de ejecución (plan 11 §1.1–§1.4)

Registro de desviaciones, decisiones técnicas y límites de verificación.
La evidencia final está en `fase1-evidencia.md`.

## Desviaciones respecto al plan

### 1.2 — Un solo commit para todo el PIN

El plan sugería varios commits para §1.2; los cambios (modelo, store con
PBKDF2 en isolate, bloqueo escalonado, recuperación, diálogo de cambio de
código, tests) resultaron inseparables sin dejar la rama en un estado que
pase los gates. Se hizo **un único commit**
(`FEAT: pin de 6 digitos, recuperacion y bloqueo escalonado`).

### 1.2.2 — PBKDF2: 50.000 iteraciones, no 100.000

Medido en el AVD de gama baja (API 28, perfil/AOT, `flutter drive`):
10.000 = 58 ms, 25.000 = 212 ms, 50.000 = 301 ms, 100.000 = **586 ms**,
200.000 = 1.938 ms. El plan permite subir a 100.000 **solo** si mide
≤ 500 ms: no cumple (586 ms). Se fija el **máximo que sí cumple: 50.000**
(301 ms, con margen para un dispositivo real más lento). Los PINes
existentes (10.000 efectivas) se re-hashean solos en su siguiente acceso
correcto, como ya estaba previsto.

### 1.3.1 — Lints estrictos sin fallout

Al añadir `prefer_const_literals_to_create_immutables`,
`use_build_context_synchronously`, `cancel_subscriptions` y `close_sinks`,
`flutter analyze` siguió en **0 problemas**: el código ya cumplía. No hubo
que tocar nada (commit `CHORE: lints estrictos`).

### 1.3.2 — Método de perfilado de frames (desviación justificada)

- `dumpsys gfxinfo` devuelve **0 frames** con Flutter: Flutter no dibuja
  por HWUI, así que ese medidor no sirve para esta app.
- `dumpsys SurfaceFlinger --latency` devuelve la capa pero con todas las
  marcas en cero en este AVD (el emulador no registra la línea de tiempo).
- Se usó el camino que el propio plan sugiere: **`flutter drive --profile`
  con `traceAction`** y los eventos del motor (`Animator::BeginFrame`)
  del timeline de Dart. Cifras en `fase1-evidencia.md`.

### 1.3.3 — La rejilla no necesita correcciones

Con 24 deslizamientos por la rejilla del comunicador: 201 frames, p99 de
9,46 ms, **0 frames > 16,7 ms**. El plan pide aplicar correcciones solo
"si la rejilla se traba": no traba, así que no se toca (Medidor de
vectores incluido sin cambios, con `cacheWidth` ya presente).

### 1.3.4 — RAM total vía `/proc/meminfo`

`dart:io` no expone la RAM total del equipo. Se lee `MemTotal` de
`/proc/meminfo` (estándar en Android/Linux) con lectura segura: si no se
puede leer, no se aplica ningún tope y la app se comporta como siempre.

## Cosas probadas con tests, no con recorrido manual

- Toda la lógica de §1.1 y §1.2 (recordatorios, PIN, bloqueo,
  recuperación) está cubierta por tests unitarios y de widget en la
  suite global (221 pruebas). Eso cuenta como verificado (§0.1.1: "test,
  emulador o dispositivo").

## Revisión por el subagente revisor y correcciones (§1.4)

Veredicto sobre `d89c255..67250f7`: CORRECCIONES, sin BLOCKER
(0 ALTA · 4 MEDIA · 6 BAJA). El revisor re-ejecutó `flutter analyze`,
`flutter test` y el build release y las cifras cuadraron con esta
evidencia. Correcciones aplicadas:

**MEDIA (todas en `5056655`):**

1. `pin_store.dart`: `getString(claveHash)!` lanzaba `TypeError` si la
   clave guardada no era texto (almacenamiento corrupto) y el gate
   quedaba sin responder. Ahora null-check + `on TypeError`, respuesta
   `incorrecto`; tests nuevos con hash y sal numéricos.
2. `ref`/`setState` sin `mounted` tras `await`: guard en
   `_entrarSiDesbloqueado()` (gate) y en el `catch` de
   `cambiar_codigo.dart`; `usageRepo.record()` del artista envuelto en
   try/catch (si el registro de uso falla, el dibujo ya está guardado).
3. Doble toque en «Entrar»: mientras dura la verificación los botones
   «Entrar» y «Usar huella o rostro» quedan apagados y un segundo
   toque no cuenta otro fallo. Test de regresión con
   `DerivadorEnEspera`: una sola derivación y un solo intento fallido.
4. «Borrar todo» de la recuperación: cancela todos los avisos
   programados (`cancelarTodoProgramado()`) **antes** de `prefs.clear()`
   e invalida ajustes, horario, perfil y recordatorios (antes quedaba
   un aviso del horario viejo y providers con datos borrados). Test
   con doble scheduler comprueba la cancelación.

**BAJA (resolución):**

- Invalidar `notificacionesPermitidasProvider` tras conceder el permiso
  por interruptor → corregido (`5056655`).
- Estado de error en la sección «Recordatorios» → corregido
  (`1338b95`): con ajustes ilegibles se muestra «No se pueden cambiar
  los recordatorios ahora.» y el interruptor no aparece; aserciones
  añadidas al test de error existente.
- Catches silenciosos del plugin → todos comentados (se añadió el del
  permiso en `1338b95`; el resto ya lo estaban).
- Constancia de dependencias nuevas → `decisiones-pendientes.md`
  (plan 00 §5.5).
- **Aviso al tope de 3000 puntos (desviación registrada, §0.3)**: el
  revisor aplica el literal del aviso también al tope de puntos. El
  plan lo enlaza al tope de la galería («pide borrar uno»), que sí está
  implementado y probado. Se decide no interrumpir un dibujo en curso
  por llegar a 3000 puntos: ese tope solo evita que el JSON de la
  galería crezca sin límite y una interrupción a mitad de trazo no
  encaja con «ninguna acción automática». Si el usuario o un revisor
  posterior lo piden, se añade el aviso.

## NO VERIFICADO (y por qué)

1. **Permiso `POST_NOTIFICATIONS` denegado en Android 13+**: el AVD es
   API 28, donde ese permiso no existe (los avisos salen sin pedirlo). El
   flujo de permiso está cubierto por tests de widget con doble falso
   (explicación literal, concesión, denegación con aviso). Requiere un
   teléfono o un AVD API 33+.
2. **Aviso con la pantalla apagada / reposo profundo (Doze)**: en el AVD
   se verificó el aviso con la app en segundo plano y tras reinicio, no
   con la pantalla apagada durante horas. Requiere el checklist de la
   Fase 3 (§3.9) en un teléfono físico.
3. **Biometría real (`local_auth`)**: el AVD no tiene sensor; los tests
   usan el doble. Requiere teléfono físico.
4. **Voz TTS real en español**: el AVD no tiene voz de Google
   instalada; los tests usan el doble. Requiere teléfono físico.
5. **Comportamiento de `allowBackup=false`**: se verificó que el build
   compila con el manifiesto y el archivo de reglas integrados; no se
   ejecutó `bmgr` para comprobar que el sistema ignora las copias.
6. **Modo calma → canal silencioso en dispositivo**: la elección de
   canal está probada por test; en el AVD no se alternó el modo calma en
   vivo para ver el segundo aviso en el canal `..._calma`.

## Preguntas que siguen pendientes del usuario

Ver `docs/informes/decisiones-pendientes.md`: keystore/`applicationId`
para Play Store y comportamiento del botón Atrás en `/home/aprender`.
