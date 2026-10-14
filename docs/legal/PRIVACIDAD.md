# Política de privacidad de BlueTalk

**Fecha de entrada en vigencia:** 13 de octubre de 2026
**Versión:** 1.0.0

## 1. Responsable del tratamiento

LimitCodev es responsable del tratamiento de los datos descritos en esta política en la aplicación BlueTalk. Correo de contacto: demo@bluetalk.app (dirección de demostración de este proyecto).

## 2. Principio general: los datos se quedan en el teléfono

BlueTalk está construida como aplicación local. En la versión actual:

- No hay servidores del desarrollador que reciban información de la app.
- No hay cuentas, ni inicio de sesión con correo o teléfono, ni sincronización activa.
- No hay publicidad, ni SDK de analítica, ni herramientas de seguimiento de terceros.
- No se envían eventos, errores ni métricas a ningún destino externo.

Todo lo que la app guarda vive en el almacenamiento privado de la aplicación, dentro del teléfono. Si la app se desinstala o el teléfono se restablece de fábrica, esos datos desaparecen.

## 3. Qué datos guarda la aplicación

Los datos se agrupan en cinco bloques:

**a) Perfil local (opcional).** Apodo elegido por la familia y avatar pictográfico. No se piden apellidos, edad, correo, teléfono ni fotografías.

**b) Uso de la comunicación.** Registro de qué pictogramas se tocan y en qué categoría caen, con fecha y hora. Sirve para enseñar en la zona de adultos qué usa el niño y para las observaciones automáticas. No guarda el texto completo de las frases construidas.

**c) Actividad y progreso.** Nivel alcanzado en cada juego, cuentos completados, dibujos guardados en el dispositivo, actividades del horario y su estado, y marcas de hábitos.

**d) Bienestar.** Check-ins emocionales diarios (una carita del 1 al 5 con su fecha). No hay notas de texto ni campos libres en este bloque.

**e) Ajustes y control parental.** Velocidad y tono de voz, tamaño de texto, modo calma, límite de tiempo de juegos, secciones bloqueadas, fecha y versión de aceptación de los documentos legales, y la huella criptográfica del PIN de la zona de adultos.

Sobre el PIN de la zona de adultos: no se guarda el PIN. Se guarda su huella calculada con PBKDF2-HMAC-SHA256 (librería `cryptography`) junto a una sal aleatoria de 16 bytes. La huella no permite recuperar el PIN. Los intentos fallidos y el instante en que termina un bloqueo también se guardan localmente para que el bloqueo sobreviva a un reinicio.

## 4. Qué datos NO recoge la app

- Nombres y apellidos de niñas, niños o personas adultas.
- Fotografías, audios grabados ni ubicación.
- Contactos del teléfono, lista de llamadas o mensajes.
- Datos de salud clínica, diagnósticos o informes.
- Identificadores publicitarios o de dispositivo con fines de seguimiento.
- Datos de uso enviados a terceros.

El reconocimiento de huella o rostro, cuando se activa, lo realiza el sistema Android con sus propios servicios biométricos. BlueTalk recibe únicamente un resultado de «correcto» o «incorrecto»; no accede ni almacena la imagen de la huella ni del rostro.

## 5. Voz y otras funciones del sistema

La lectura de pictogramas usa el sintetizador de voz instalado en el teléfono. El texto que se lee se pasa al sistema Android para que lo pronuncie; no queda registrado por BlueTalk. Las notificaciones, si se autorizan, se generan localmente con el sistema de notificaciones de Android.

## 6. Base jurídica

El tratamiento se basa en el consentimiento de la persona adulta responsable, otorgado al aceptar los Términos y la Política de privacidad con la casilla de consentimiento parental. Ese consentimiento se guarda con su fecha y su número de versión y puede retirarse borrando los datos de la app o desinstalándola.

## 7. Menores de edad

La app está pensada para uso supervisado por personas adultas. No se recogen deliberadamente datos de menores más allá de los bloques descritos en el apartado 3, todos ellos locales y de naturaleza no identificativa. La familia responsable evita introducir datos identificativos en campos de texto libres.

## 8. Sincronización futura con la nube (Supabase)

La arquitectura prevé, para versiones futuras, una sincronización opcional con un servicio en la nube (Supabase) para conservar los datos si el teléfono se pierde. Mientras esa función exista:

- permanecerá desactivada de forma predeterminada;
- se pedirá consentimiento explícito y adicional antes de activarla;
- se informará de qué bloques se suben, dónde se guardan y cómo se borran;
- no se sincronizará nada mientras el usuario no lo active.

En esta versión no existe sincronización: ningún dato sale del teléfono.

## 9. Conservación y borrado

Los datos se conservan mientras la app esté instalada. Para eliminarlos:

- Borrar los datos de la app desde Ajustes de Android (Aplicaciones › BlueTalk › Borrar datos) elimina todos los bloques, incluida la huella del PIN.
- Desinstalar la app elimina el almacenamiento privado asociado.
- Borrar solo el perfil o el historial desde la propia app, cuando esa opción esté disponible, elimina los bloques correspondientes sin tocar el resto.

Restaurar una copia del teléfono desde el sistema Android puede restaurar también los datos de la app; eso depende de las copias de seguridad configuradas en el dispositivo, no de BlueTalk.

## 10. Derechos de las personas

Cualquier persona responsable puede ejercer los derechos de acceso, rectificación, supresión, oposición y limitación escribiendo a demo@bluetalk.app. Como los datos viven en el teléfono y no en un servidor, la vía más rápida de acceso y rectificación es la propia app o el borrado descrito en el apartado 9.

Si en el futuro hay datos en la nube, el mismo correo servirá para solicitar una copia exportable en formato legible y la supresión de la cuenta.

## 11. Seguridad aplicada

- Huella del PIN con sal aleatoria y función de derivación de claves (nunca el PIN en claro).
- Bloqueo de 60 segundos tras cinco intentos fallidos, con persistencia local.
- Almacenamiento privado de la app: otros procesos del teléfono no acceden a esos archivos sin permiso del sistema.
- Sin tráfico de red en la versión actual, por lo que no existe superficie de ataque por red proveniente de la app.

Ningún sistema es infalible; la app no garantiza seguridad absoluta frente a un dispositivo con el sistema comprometido.

## 12. Servicios de terceros y transferencias

La app no incluye SDK de terceros con fines publicitarios o de analítica. Google Play Store actúa como canal de distribución y aplica sus propias condiciones y políticas en la descarga, actualización y pago, si llegara a haberlo. Si en el futuro se incorpora la sincronización en la nube, el proveedor de infraestructura figurará en este apartado con su ubicación y sus garantías.

## 13. Cambios en esta política

Cada versión de la política lleva número y fecha. Los cambios sustanciales exigirán volver a aceptar el documento desde la zona de adultos; la fecha y la versión aceptadas quedan visibles allí.

## 14. Contacto

Correo: demo@bluetalk.app (dirección de demostración de este proyecto).
Última actualización: 13 de octubre de 2026, versión 1.0.0.
