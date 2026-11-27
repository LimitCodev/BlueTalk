# Lo que falta para publicar BlueTalk en Google Play

**Fecha:** 26 de noviembre de 2026
**Edición:** `play` (AAB). La edición `directa` (APK con filtro web y monitoreo) no va a Play.
> **Actualización (26-nov, tarde):** el dueño decidió publicar con suscripción y nube cifrada (diseño en `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md`). La §4 «No falta nada para la v1» queda superada. Las decisiones que dependen del dueño están en `docs/informes/solo-el-dueno-2026-11-26.md`.

**Fuente:** revisión del Panel de Play Console y del repositorio en esta fecha. Lo que no se comprobó hoy figura como **NO VERIFICADO**.

## Resumen

| Bloque | Estado | Bloquea publicar | Quién decide o actúa |
|---|---|---|---|
| Declaraciones y ficha en Play Console | 11 de 12 hechas | Sí (falta Seguridad de los datos) | Dueño (D-1) |
| AAB firmado | No hay keystore en `~/keystores/` | Sí | Dueño |
| Prueba interna | No iniciada | No (es opcional) | Dueño + agente |
| Prueba cerrada (12 testers × 14 días) | No iniciada | Sí, para producción | Dueño |
| Capturas de la ficha | Subidas, en desorden y quizá desactualizadas | No, pero afecta la calidad | Dueño |
| AWS | No hace falta para la v1 | No | — |
| Funciones futuras (premium, voces, estadísticas agregadas) | Sin construir | No para la v1 | Dueño |

## 1. Play Console

### Hecho el 26-nov-2026 (guardado, sin enviar a revisión)

- Apps gubernamentales: No.
- ID de publicidad: No (el manifiesto `playRelease` no pide `AD_ID` ni `INTERNET`).
- Funciones financieras: ninguna.
- Salud: «Control del estrés, relajación y agudeza mental».
- Comerciante: Sí, con los términos `https://limitcodev.github.io/BlueTalk/terminos.html`.
- Categoría: Educación. Contacto: `bluetalk.soporte@gmail.com` y `https://limitcodev.github.io/BlueTalk/`, sin teléfono.
- Ficha: nombre, descripción breve y completa (desde `docs/play/ficha.md`), ícono, gráfico destacado y 6 capturas. Ícono y gráfico etiquetados como hechos con IA.

Ya estaban hechos antes: política de privacidad, acceso a la app, anuncios, clasificación de contenido y público objetivo (menores de 5, 6-8 y 9-12, así que aplica la Política de Familias).

### Falta

- [ ] **Seguridad de los datos.** Bloqueada por la duda D-1 de `dudas_playstore_bluetalk.md`. Recomendación: declarar «No recopila, no comparte» mientras la app no tenga red, y cambiarla cuando salga una versión que envíe datos.
- [ ] **Ordenar las capturas** en la ficha: hoy están en el orden 05, 03, 04, 06, 01, 02. Se ordenan arrastrándolas.
- [ ] **Revisar que las capturas muestren la interfaz actual.** Las de `docs/play/capturas/telefono/` usan la barra de pestañas inferior. El informe del 18-nov avisa que son anteriores al menú principal del 12 y 16-nov. Si cambió, regenerarlas y reemplazarlas.
- [ ] Opcional: capturas de tablet (2–4) y de 1080 px o más por lado (Play las pide para las promociones).
- [ ] **Enviar los cambios a revisión** desde «Descripción general de la publicación». Lo hace el dueño o da el OK explícito.

## 2. Firma y versión

- [ ] Restaurar `~/keystores/bluetalk-release.keystore` desde la copia del dueño. Si se perdió y nunca se subió nada a Play, se puede crear una clave nueva.
- [ ] Ejecutar `./scripts/build-aab.sh` en una terminal normal (fuera del sandbox) y verificar firma, `targetSdk 36`, `minSdk 24` y 16 KB.
- [ ] Decidir la versión pública: hoy `pubspec.yaml` dice `0.1.0+1`. Cada subida a Play necesita un `versionCode` mayor.
- [ ] Inscribir la app en Play App Signing al subir el primer AAB (lo acepta el dueño).
- [ ] Guardar `mapping.txt` y los símbolos de `dist/simbolos/` fuera del repo.

## 3. Pruebas en Play

1. [ ] Subir el AAB a **prueba interna** y probarlo en un teléfono físico.
2. [ ] Subirlo a **prueba cerrada** con 15 correos o más (mínimo 12), adultos y sin datos de menores.
3. [ ] Mantener la prueba 14 días seguidos y pedir que usen la app de verdad.
4. [ ] Responder el formulario de acceso a producción (cómo se reclutaron los testers, su participación y los comentarios recibidos).
5. [ ] Solicitar producción y esperar la revisión (habitual: 7 días o menos).

## 4. La app: qué falta para que sea funcional

### No falta nada para la v1

La app funciona sin red y sin AWS. Lo comprobado en el repositorio:

- Los informes del modo padre (`lib/features/padre/informes/`) se calculan en el teléfono con los eventos de uso reales. `resumenes_siembra.dart` solo agrupa los eventos que ya existen; no inventa datos.
- La voz usa el sintetizador del teléfono (`flutter_tts`). No necesita Polly.
- La política dentro de la app y la publicada coinciden en la versión `1.3.0` (`lib/features/padre/legal/textos_legales.dart:38`).
- Decisión del dueño (7-nov-2026, `docs/informes/decisiones-pendientes.md`): «AWS solo fuera de la app; la app sigue sin red en la v1».

**NO VERIFICADO hoy:** `flutter analyze` y `flutter test` (el último resultado conocido es 456/456 del 18-nov) y la prueba del AAB en un teléfono físico.

### AWS: qué existe y qué no

| Pieza | Para qué | Estado |
|---|---|---|
| `infra/aws/cdn.yaml` (S3 + CloudFront + alarma de gasto) | Servir la web legal | Lista y probada **en simulación**. No hace falta: la política ya está en GitHub Pages |
| `scripts/aws/polly/` | Grabar voces naturales antes de compilar | Generador listo; falta el reproductor de MP3 en la app |
| Cuenta de AWS | Todo lo anterior | No creada |
| Envío de estadísticas o informes a la nube | Investigación con datos agregados | **No existe.** No hay código, endpoint ni permiso `INTERNET` en la edición Play |

### Si se quieren estadísticas agregadas en AWS (versión futura)

Es la idea de la duda D-1. Hoy no hay nada construido. Haría falta, en este orden:

1. Decidir qué contadores se envían, con qué frecuencia y por cuánto tiempo se guardan.
2. Crear el receptor en AWS (por ejemplo API Gateway + Lambda + S3 o DynamoDB), con alarma de gasto y sin guardar IP ni identificadores del dispositivo.
3. Añadir `INTERNET` solo a la edición `play` y el envío en la app, a través de `CanalNativo`/las puertas del core. Sin SDK de analítica de terceros que no estén aprobados para Familias.
4. Pedir el consentimiento del adulto (tras el PIN), desactivado por defecto, y permitir retirarlo.
5. Actualizar a la vez `docs/legal/PRIVACIDAD.md`, `TERMINOS_Y_CONDICIONES.md`, `textos_legales.dart` (subir `versionLegal`), la web publicada y el formulario de Seguridad de los datos.
6. Probar con `aws-emu` antes de tocar AWS real.

### Funciones opcionales pendientes de decisión (no bloquean la v1)

- **Premium con Play Billing:** elegir compra única o suscripción y su precio, y aprobar `in_app_purchase` (`docs/infra/aws-freemium.md` §5). Si se cobra, revisar la Seguridad de los datos y los términos (hoy dicen «no se ofrecen pagos»).
- **Voces naturales de Polly:** elegir la voz, crear la cuenta de AWS y construir el reproductor de MP3.
- **Voz propia del adulto y reordenar el tablero:** plan 15, sin aprobar.
- **Mascota:** el candado dice «SECURE» en inglés.

## 5. Cuentas y legal

- [ ] Plan para el 1-mar-2027: Google publicará el teléfono y la dirección del comerciante. Decidir entre un teléfono de negocio con oficina virtual, o crear una empresa con cuenta de organización.
- [ ] Confirmar que alguien atiende `bluetalk.soporte@gmail.com`.
- [ ] Revisar las fotos, audios e imágenes personales de la raíz del repo (`AUDIO-*.mp4`, `WhatsApp Image*.jpeg`, `xdgi.jpeg`, `Ynocencio_foto.jpg`) antes de hacer público el repositorio.

## 6. Decisiones del dueño, en orden

1. D-1: Seguridad de los datos («No» ahora o «Sí» ya).
2. Keystore: restaurar o crear uno nuevo.
3. Capturas: regenerarlas o solo ordenarlas.
4. Versión pública (`0.1.0` o `1.0.0`).
5. Testers para la prueba cerrada.
6. Modelo de cobro y si habrá estadísticas en AWS (afecta a los puntos 1 y 5 de la sección 4).
