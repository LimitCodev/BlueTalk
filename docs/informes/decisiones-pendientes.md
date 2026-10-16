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
