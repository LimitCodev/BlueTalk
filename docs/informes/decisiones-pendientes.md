# Decisiones pendientes del usuario

Nada de esto decide el equipo: son preguntas que solo el usuario puede responder.
Se dejan escritas y se continúa con todo lo que no depende de ellas.

## Keystore y `applicationId` (para publicar en Play Store)

- Falta el keystore de firma y confirmar el `applicationId` definitivo.
- **No bloquea** probar la app en local: el APK debug se instala y se prueba sin ellos.
- Pregunta: ¿qué nombre de paquete usamos (p.j. `com.tunombre.bluetalk`) y quién
  custodia la clave de firma? (Si la generamos, la frase de paso se la entregamos
  al usuario y no se guarda en el repositorio.)

## Botón «Atrás» (PopScope) en `/home/aprender`

- Elevado por el revisor en `docs/informes/ola2-comunicador-juegos.md`
  («Para el coordinador», punto 3): `lib/app/router.dart` no define el
  comportamiento del botón Atrás en `/home/aprender` ni en las vistas internas;
  hoy es el comportamiento por defecto de go_router.
- Pregunta: ¿el botón Atrás (a) sale de la app, (b) vuelve a la pantalla
  «Comunicar» o (c) lo gestiona el gate de límites del tiempo de pantalla?
- Mientras tanto: se conserva el comportamiento por defecto (ninguna decisión
  tomada por el equipo).
