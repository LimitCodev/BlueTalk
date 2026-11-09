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
  libertad.
- **Estado:** implementado el 2026-10-20 en el plan 14
  (`docs/plan/14-filtro-web.md`) como **VPN local que solo intercepta DNS**.
  El adulto lo enciende desde Control › Filtro de páginas. La app no envía
  datos a servidores del desarrollador; las consultas permitidas se
  reenvían al DNS de la red y las bloqueadas se responden en el teléfono.
- **Límites que el dueño debe conocer** (están también en la pantalla y en
  la evidencia):
  - bloquea el dominio completo, no una página suelta;
  - no bloquea direcciones IP literales, apps con su propia resolución
    (DoH/DoT) ni DNS sobre TCP;
  - un niño que apague la VPN en Ajustes de Android la desactiva;
  - si el teléfono se reinicia, hay que activar «VPN siempre activa» en
    Android para que el filtro vuelva solo;
  - el filtro no sustituye el filtrado del Wi-Fi escolar ni la supervisión.
- **Decisiones que siguen en manos del dueño:**
  1. Revisar y publicar la política de privacidad 1.1.0 y los términos
     1.1.0 (la app ahora pide aceptarlos de nuevo; el cambio explica la
     VPN y el DNS).
  2. Decidir cómo se distribuye el APK de la prueba escolar. Si se publica
     en Google Play, hay que declarar el uso de `VpnService` en Play
     Console y completar la declaración de seguridad de datos.
  3. Decidir si los teléfonos del colegio serán administrados (MDM) y si
     se añadirá una lista de dominios propia del colegio.
  4. Configurar «VPN siempre activa» y el DNS familiar del router en los
     equipos de la prueba; son ajustes del colegio, no de la app.
- Alternativas descartadas para esta entrega: el DNS privado del sistema
  (solo guía, se puede desactivar y no cubre apps con DNS propio) y no
  implementar nada (Family Link/Samsung Kids). Se prefirió la VPN local
  porque es la única que filtra el navegador y las apps a la vez sin enviar
  datos a un servidor.

## Administrador de dispositivo (resuelto 2026-11-08)

- El dueño eligió **quitarlo** (P0-3 de `requisitosPlayStore.md`). Play
  prohíbe usar el administrador para bloquear la desinstalación.
- Se eliminaron `ProteccionReceiver`, `ProteccionChannel`,
  `device_admin.xml`, el canal `bluetalk/proteccion`, la tile de Control y
  la entrada del asistente de permisos.
- La app se desinstala como cualquier otra. Si más adelante se quiere una
  barrera, la alternativa permitida es el **anclaje de pantalla** de
  Android, que el adulto activa y puede salir con el gesto del sistema; no
  está implementado.

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

## Ruta de Play (resuelto 2026-11-08)

El dueño eligió la **ruta A**: la edición `play` no lleva VPN, acceso al uso ni
`INTERNET`. El filtro y el monitoreo siguen en la edición `directa`. Detalle en
`docs/informes/p0-2-ruta-a.md`.

## BLOQUEADO: Atrás en una categoría del Comunicador (2026-11-09)

En el emulador (release `play`, API 28), Atrás dentro de una categoría cierra la
app en vez de volver al tablero. El commit `9f8acae` dice arreglarlo: su prueba
de widget pasa, pero **en el emulador el defecto sigue**.

- Un `PopScope` en `ComunicadorScreen` tampoco lo arregla en el emulador.
- Quitar `SystemNavigator.pop()` de `manejarAtras` no evita el cierre desde el
  inicio de Comunicar: esa salida no viene del manejador del shell. Es probable
  que `saleConAtrasProvider = false` (kiosko) tampoco funcione en un teléfono.
- `handlePopRoute()` en `flutter test` no reproduce el fallo: las pruebas P1 no
  demuestran este caso.
- Atrás desde Rutinas sí vuelve a Comunicar. Causa aún sin identificar.

## Freemium y AWS (abierto el 2026-11-07)

Decidido por el dueño: modelo freemium; AWS solo fuera de la app
(opciones 1–3 de `docs/infra/aws-freemium.md`); la app sigue sin red en la v1.

Falta decidir:

- **Producto de Play:** compra única (recomendado) o suscripción, y precio.
- **Dependencia `in_app_purchase`** para conectar Play Billing (§5 del doc).
- **Reproductor de MP3:** canal nativo propio (sin dependencia, recomendado)
  o `audioplayers`.
- **Voz premium de la v1:** escuchar Lupe, Pedro, Mia, Andrés, Lucia y
  Sergio, y elegir una para incluirla en el APK.
- **Cuenta de AWS:** quién la crea, con MFA, y qué correo recibe la alarma
  de gasto.
- **Correo e identidad legal reales:** `scripts/aws/publicar_legal.sh` se
  niega a publicar mientras quede `demo@bluetalk.app`.

