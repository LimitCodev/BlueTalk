# Mejoras del modo padre — 2026-10-19 (solicitud directa del dueño)

Origen: el dueño pidió tres cosas tras probar la app: (1) el candado del
encabezado del modo padre «no tiene sentido», (2) «alguna forma de
recuperar la contraseña del modo padre por si olvidas la contraseña» sin
perder datos, y (3) bloqueo de páginas +18 en todo el teléfono. El punto
(3) queda como decisión pendiente (no se implementa aún); además llegó una
solicitud de incorporar detección/cribado de TEA que **se rechaza por
regla dura** del proyecto (detallado abajo).

Gates de esta tanda: `flutter analyze` 0 · `flutter test` **258/258**
(antes: 252; +6 tests nuevos).

## 1. Candado redundante del encabezado (HECHO, commit `7c92732`)

- El problema: el icono de candado de la cabecera «Modo padre» solo
  re-mostraba el PIN dentro del propio modo padre; la X de al lado ya
  cerraba la sesión Y salía, así que el candado aportaba confusión y nada
  más (queja literal del dueño: «sirve para dirigirte al modo parental,
  cosa que no tiene sentido»).
- Arreglo: se **elimina** el candado. La X («Salir del modo padre») es ya
  el cierre de sesión completo: `cerrarSesion()` bloquea el gate y sale a
  Ajustes. Seguridad idéntica, cabecera limpia.
- Tests ajustados: `test/padre/padre_screen_test.dart` («salir del modo
  padre cierra la sesión y el gate pide el PIN») y `test/core/router_test.dart`
  (cierre desde el controlador, ya sin botón).

## 2. Código de recuperación del PIN (HECHO, commit `6add375`)

Antes existía **un solo** camino ante un PIN olvidado: escribir `BORRAR`
(plan 11 §1.2), que borraba **todo** el dispositivo y volvía al
onboarding. El dueño pidió recuperar el acceso **sin perder datos**.

Diseño (sin dependencias nuevas, misma seguridad que el PIN):

- **Almacenamiento** (`pin_store.dart`): el código tiene 8 caracteres del
  alfabeto `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (sin I, O, 0 ni 1 para no
  confundir al leerlo o teclearlo) y se muestra formateado `XXXX-XXXX`.
  En disco solo vive su huella PBKDF2-HMAC-SHA256 con sal y parámetros
  registrados, igual que el PIN; el código en claro se ve **una sola vez**.
- **Generar** (nuevo diálogo en Control → «Código de recuperación»): si no
  existe, un botón lo genera y lo muestra una vez con aviso de guardarlo
  en papel; si ya existe, la única opción es regenerarlo (el anterior deja
  de valer); no hay forma de volver a ver el código guardado.
- **Recuperar** («¿Olvidaste el código?»): si el dispositivo tiene código,
  aparece primero la opción «Recuperar sin borrar nada». El código se
  valida contra su huella y, si es correcto, se borra **solo** el PIN: el
  progreso, el horario, los ajustes y el propio código de recuperación se
  conservan, y el gate queda en «Crea tu código de 6 dígitos». El camino
  destructivo `BORRAR` sigue disponible debajo, sin cambios.
- **Bloqueo**: el código de recuperación **comparte** los contadores de
  intentos con el PIN (quinto fallo de cualquiera de los dos → espera de
  60 s escalonada). Formato inválido no cuenta como intento, igual que el
  PIN.

Tests añadidos (+6): huella sin código en claro; verificación con y sin
formato; bloqueo compartido; `borrarSoloPin` conserva datos y código;
flujo completo de widget (código erróneo → aviso; correcto → gate en fase
«crear» con datos intactos; sin código → se explica que solo queda
borrar); y desde Control: generar, ver el código una vez, huella guardada
y reapertura en modo «regenerar». La semilla de los tests de widget usa un
hash precalculado con la propia librería `cryptography` fuera de
FakeAsync (mismo patrón que el PIN).

## 3. Cribado/evaluación de TEA con software (NO implementado — regla dura)

Llegó un texto con herramientas reales de cribado digital (M-CHAT-R/F,
eye-tracking, prosodia, etc.) pidiendo «mejorar el proyecto» en esa
dirección. **No se implementa** porque contradice reglas no negociables ya
escritas por el propio dueño:

- Principios de producto (AGENTS.md / plan 00): «orientativa, no es
  diagnóstico»; público vulnerable; el plan 05 descarta explícitamente
  datasets de screening en su catálogo ético.
- Ayer mismo se publicó (commit `00ee6bc`) el disclaimer «esta app **no
  realiza screening ni evaluaciones**», en espejo en `docs/legal/TERMINOS_Y_CONDICIONES.md`
  §8, con test que exige ambos.

Cualquier cambio aquí **exige que el dueño reabra el plan maestro** (es su
decisión, queda anotada en `decisiones-pendientes.md`). Argumento técnico
además: las herramientas citadas son SaMD validados clínicamente con
cámara, sensores y revisiones regulatorias (FDA); no son comparables a
una app offline de comunicación aumentativa.

## 4. Bloqueo de contenido +18 en todo el teléfono (PENDIENTE de decisión)

Petición del dueño: que el modo parental pueda bloquear la búsqueda de
páginas +18 para que el niño use el celular con libertad. No existe hoy en
ningún plan; las opciones reales (con sus contrapartidas) están escritas
en `decisiones-pendientes.md`. **No se codifica hasta que el dueño elija.**

## NO VERIFICADO (requiere teléfono físico)

- Flujo real de generación y uso del código de recuperación en el móvil
  (probado en tests de widget, no en dispositivo).
- Diálogo de generación y legibilidad del código en pantalla real.
