# Decisiones pendientes del usuario

Nada de esto decide el equipo: son preguntas que solo el usuario puede responder.
Se dejan escritas y se continúa con todo lo que no depende de ellas.

## Keystore y `applicationId` (para publicar en Play Store)

- Falta el keystore de firma y confirmar el `applicationId` definitivo.
- **No bloquea** probar la app en local: el APK debug se instala y se prueba sin ellos.
- Pregunta: ¿qué nombre de paquete usamos (p.j. `com.tunombre.bluetalk`) y quién
  custodia la clave de firma? (Si la generamos, la frase de paso se la entregamos
  al usuario y no se guarda en el repositorio.)

### Urgente desde 2026-10-15: Play Protect bloquea el APK

- El APK release se firma hoy con la clave de **depuración** de plantilla
  (`CN=Android Debug`, verificado con `apksigner --print-certs`) y en el
  teléfono del usuario Play Protect lo bloquea: «Play Protect no vio una
  app de este desarrollador antes». Instalación posible tocando el enlace
  «Instalar de todas formas» del propio diálogo.
- **RESUELTO (2026-10-15, decisión del usuario: sí)**: keystore propio
  generado en `~/keystores/bluetalk-release.keystore` (alias `bluetalk`,
  RSA 2048, validez 10.000 días, `CN=BlueTalk`), **fuera del
  repositorio**. `android/key.properties` (gitignored, permisos 600)
  apunta a él y el release ya firma con esa clave; si `key.properties`
  no existe en otra máquina, el build vuelve a debug para no bloquear
  el desarrollo. La frase de paso se entregó al usuario en el chat y
  **no está escrita en ningún archivo del repositorio**. Custodio: el
  usuario — debe guardarla y copiar el `.keystore` fuera de este
  equipo; sin ella no se podrán firmar futuras versiones ni dar de alta
  la app en Play Store.
- Aviso honesto (verificado con política actual de Google): una firma
  release **suaviza** el veredicto (la clave debug es el patrón típico de
  APKs reempaquetados) pero **no elimina** el aviso de «desarrollador
  desconocido» al instalar fuera de Play Store. Eliminarlo del todo solo
  se consigue publicando en Play Store (cuenta de desarrollador =
  decisión del usuario; el equipo no crea cuentas).
- Dato del APK actual: `compileSdk/targetSdk 36`, `minSdk 24`
  (Android 7.0 en adelante — teléfonos anteriores a 2016 no lo
  instalarían por versión, mensaje distinto al de Play Protect).

## Botón «Atrás» (PopScope) en `/home/aprender`

**RESUELTA (2026-10-16, por el dueño):** Atrás debe moverse dentro de la app, no cerrarla. Comportamiento exigido en `docs/plan/13-pulido-uso-real.md` P1.

- Elevado por el revisor en `docs/informes/ola2-comunicador-juegos.md`
  («Para el coordinador», punto 3): `lib/app/router.dart` no define el
  comportamiento del botón Atrás en `/home/aprender` ni en las vistas internas;
  hoy es el comportamiento por defecto de go_router.
- Pregunta: ¿el botón Atrás (a) sale de la app, (b) vuelve a la pantalla
  «Comunicar» o (c) lo gestiona el gate de límites del tiempo de pantalla?
- Mientras tanto: se conserva el comportamiento por defecto (ninguna decisión
  tomada por el equipo).

## Dependencias nuevas de la Fase 1 (constancia, plan 00 §5.5)

No son preguntas: decisiones técnicas ya tomadas conforme al plan,
anotadas aquí como constancia.

- `flutter_timezone` (runtime): zona horaria real de los avisos,
  exigida por el plan Fase 1 §1.1 (la del dispositivo, no UTC).
- `flutter_driver` + `integration_test` (solo `dev_dependencies`):
  perfilado §1.3.2 y benchmark PBKDF2 §1.2.2. Ambas del SDK de Flutter;
  no añaden descargas de terceros ni permisos a la app.

## Configuración de git (§5.1 «solo el nick LimitCodev»)

- El historial de git arrastra el correo personal del dueño en commits
  preexistentes (lo detectó el revisor de la etapa A). Cambiar
  `git config user.name/user.email` para los próximos commits es
  inmediato; el pasado no se reescribe sin su permiso.
- Pregunta: ¿quiere que ajuste git a «LimitCodev <limitcodev@users.noreply.github.com>»?

## Bloqueo de contenido +18 en todo el teléfono (solicitud del dueño, 2026-10-19)

- Petición: que el modo parental pueda bloquear la búsqueda de páginas +18
  en el **celular entero**, para que el niño use el dispositivo con
  libertad. No está en ningún plan; toca permisos y privacidad, así que
  es decisión del dueño antes de escribir una línea de código.
- Opciones reales (todas offline: ningún dato sale del dispositivo):
  1. **VPN local de filtrado DNS** (la única que bloquea el navegador y
     cualquier app a la vez): BlueTalk crea un túnel local que filtra
     dominios +18 con una lista incluida en la app. Contrapartidas:
     Android muestra su propio diálogo «Solicitud de conexión», Google
     Play exige declarar el uso de `VpnService`, y la documentación de
     permisos/privacidad hay que reescribirla (la app «no usa internet»
     pasa a «no envía datos; filtra el tráfico localmente»).
  2. **DNS privado del sistema**: BlueTalk solo guía con un toque para
     que el adulto active el «DNS familiar» de Android. Sin permisos
     nuevos ni VPN, pero se puede desactivar desde Ajustes y solo cubre
     DNS (no apps con su propia resolución).
  3. **No implementarlo** y apoyarse en los controles del sistema
     (Google Family Link / Samsung Kids), que ya hacen esto y están
     validados.
- Pregunta: ¿cuál quieres? (Recomendación del equipo: 2 por simplicidad y
  transparencia; 1 solo si el bloqueo a nivel de teléfono es imprescindible.)

## Cribado/evaluación de TEA con software (solicitud del dueño, 2026-10-19)

- Llegó un texto proponiendo incorporar detección de TEA (M-CHAT-R/F,
  eye-tracking, análisis de prosodia…). El equipo **no lo implementa**:
  contradice reglas duras escritas por el propio dueño (plan 00
  principios de producto «orientativa, no es diagnóstico»; catálogo ético
  del plan 05 que descarta datasets de screening; disclaimer «no realiza
  screening ni evaluaciones» ya publicado con su test, commit `00ee6bc`).
- Si el dueño lo quiere igualmente, debe **reabrir el plan maestro** con
  una decisión explícita suya y asesoría legal; no se avanza por cuenta
  propia. Detalle técnico en `docs/informes/mejoras-modo-padre.md` §3.

## Correo de contacto y soporte (FAQ del modo padre)

- Hoy el correo impreso en los Términos es `demo@bluetalk.app`
  (dirección de demostración, declarada como tal en el propio texto).
- El plan 13 P6.2 pide «FAQ y contacto en el modo padre» con un correo
  real: **no se inventa ninguno**.
- Pregunta: ¿qué correo de soporte quiere publicar (y crearlo si no
  existe)? La pantalla de FAQ queda pendiente de esa respuesta.
