# Dudas de Play Console — BlueTalk

Decisiones que el agente no tomó solo. Se definen con el grupo.

### D-1. Seguridad de los datos: ¿declarar que se recopilan datos agregados?
- **Fecha:** 2026-11-26
- **Dónde:** Play Console → Política y programas → Contenido de la app → Seguridad de los datos
- **Qué pide Google:** si la app recopila o comparte datos de usuarios (cualquier dato que salga del teléfono), qué tipos, para qué, si van cifrados en tránsito y si el usuario puede pedir su borrado. Incluye el compromiso con la Política de Familias.
- **Lo que hay en el repo:**
  - El manifiesto compilado `playRelease` (18-nov) no pide `INTERNET`; `pubspec.yaml` no trae paquetes de red, analítica ni anuncios.
  - `docs/legal/PRIVACIDAD.md` §2 (versión 1.3.0, publicada en `https://limitcodev.github.io/BlueTalk/privacidad.html`): «No se envían eventos, errores ni métricas a ningún destino externo».
  - `docs/informes/declaraciones-play-2026-11-19.md` §1 recomienda: no recopila, no comparte, compromiso con Familias: Sí.
  - Público objetivo ya guardado en Play: menores de 5, 6-8 y 9-12 (aplica la Política de Familias).
- **Postura del dueño (2026-11-26):** marcar «Sí, recopila». La idea es usar en el futuro datos numéricos agregados (contadores de cuántas personas usan cada función por periodo, en AWS) para investigación, sin datos personales ni sensibles, y ajustar los términos para pedir permiso antes.
- **Opciones:**
  1. Declarar «No recopila» ahora y actualizar el formulario y la política cuando salga la versión que envíe contadores.
  2. Declarar «Sí, recopila» ya (tipo probable: «Actividad en la app → Interacciones con la app», fin «Analítica»), y cambiar antes la política y los términos.
- **Recomendación del agente:** opción 1. La edición Play actual no puede enviar nada (no tiene `INTERNET`). Declarar «Sí» hoy contradice la política publicada y el comportamiento real, y Google rechaza las declaraciones que no coinciden con la app. El formulario se puede cambiar en cualquier momento; lo que exige Google es que esté al día antes de publicar la versión que sí envía datos. Para esa versión futura hará falta: añadir `INTERNET`, usar solo SDK aptos para Familias, no enviar identificadores del dispositivo, pedir consentimiento del adulto, y actualizar `PRIVACIDAD.md`, `TERMINOS_Y_CONDICIONES.md`, `lib/features/padre/legal/textos_legales.dart` y este formulario a la vez.
- **Bloquea:** la tarea «Seguridad de los datos» del Panel (1 de las 12 de «Termina de configurar tu app»). No bloquea guardar las demás declaraciones ni la ficha.
- **Decisión del dueño (2026-11-26):** «Sí, recopila». Condición: el proyecto se adapta para que la versión publicada cumpla la propuesta inicial (suscripción que financia servicios en AWS, con controles contra el abuso).
- **Cómo se aplica:** el formulario se rellena cuando el diseño fije qué datos salen del teléfono (tipos, fin, cifrado en tránsito y borrado). Marcar «Sí» sin esos tipos obligaría a adivinarlos. Hasta entonces la tarea sigue abierta en el Panel.
- **Estado:** decidida; formulario pendiente del diseño de la suscripción

### D-2. Capturas de la ficha
- **Fecha:** 2026-11-26
- **Dónde:** Play Console → Ficha principal → Capturas de teléfono
- **Hallazgo:** las 6 capturas subidas no muestran el menú principal (`/inicio`) con el que arranca la app. Las del menú en `docs/informes/capturas/14a-*` llevan la cinta «DEBUG».
- **Decisión del dueño:** regenerarlas sin la cinta (build profile o release), con un apodo ficticio, y pedir OK antes de subirlas. Se hará al final, cuando la interfaz de la suscripción esté lista.
- **Estado:** decidida; pendiente de ejecutar

### D-3. Versión pública
- **Fecha:** 2026-11-26
- **Dueño:** «la versión más reciente», después de editar el proyecto para que sea funcional.
- **Criterio del agente:** el primer AAB de Play sale como `1.0.0+1` (recomendación de `requisitosPlayStore.md` §8, decisión 13). Cada subida posterior sube el número tras el `+`.
- **Estado:** decidida (número a confirmar al compilar)

### D-4. Keystore
- **Fecha:** 2026-11-26
- **Decisión del dueño:** tiene copia y la restaura en `~/keystores/bluetalk-release.keystore`. El agente no lee ni copia sus contraseñas.
- **Estado:** pendiente del dueño
