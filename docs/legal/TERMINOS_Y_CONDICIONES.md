# Términos y condiciones de uso de BlueTalk

**Fecha de entrada en vigencia:** 13 de octubre de 2026
**Versión:** 1.0.0

## 1. Identificación del servicio

BlueTalk es una aplicación móvil de comunicación aumentativa y alternativa (CAA) dirigida a niñas, niños y a personas que necesitan apoyo para comunicarse. Se distribuye a través de Google Play Store con el identificador de paquete `com.limitcodev.bluetalk`. La persona responsable del desarrollo y del mantenimiento del servicio es LimitCodev (en adelante, «el desarrollador»).

Correo de contacto: demo@bluetalk.app. Es una dirección de demostración para este proyecto; las consultas recibidas allí se atienden en el entorno de pruebas.

## 2. Objeto de estos términos

Estos términos regulan el acceso y el uso de BlueTalk. Al marcar la casilla de aceptación en la zona de adultos, la persona adulta responsable que instala la aplicación declara haber leído estos términos y la Política de privacidad, y se obliga a cumplirlos en nombre de las personas menores que usen la app.

Si la persona adulta responsable no está de acuerdo con alguna parte de estos términos, no debe instalar la aplicación ni permitir su uso.

## 3. Alcance de esta versión

BlueTalk se encuentra en una fase de versión preliminar (MVP) de prueba. Durante esta fase:

- No existen cuentas de usuario ni autenticación en la nube. No hay registro con correo, teléfono ni redes sociales.
- Todos los datos que produce la app se guardan en el almacenamiento local del teléfono y no se envían a servidores del desarrollador.
- Los pictogramas, cuentos, actividades de horario y ejemplos incluidos son contenido de demostración incluido con fines de prueba; no representan casos clínicos ni recomendaciones particulares.
- No se ofrecen pagos, suscripciones ni funciones premium. Cualquier versión futura con pago se anunciará por separado y requerirá aceptación expresa de condiciones adicionales.
- Ciertas métricas de la zona de adultos se etiquetan como «Datos de demostración» mientras no exista sincronización con un servicio en la nube.

## 4. Uso por menores de edad y consentimiento parental

La app está dirigida a menores de edad. La instalación y el uso quedan supuestos bajo la supervisión de la persona adulta responsable (madre, padre o tutor legal).

La persona adulta responsable se compromete a:

- Revisar y configurar la app antes de entregar el teléfono al menor, en especial el límite de tiempo de juegos y el acceso a la zona de adultos.
- No compartir el código PIN de la zona de adultos con menores, ni dejarlo escrito en lugares visibles.
- Supervisar el contenido que el menor crea o exporta desde la aplicación.

La aceptación de estos términos por parte de la persona adulta constituye el consentimiento parental exigible para el uso de la app por menores en este proyecto.

## 5. Perfil local y datos que introduce la persona usuaria

La app crea un perfil local opcional compuesto por un apodo y un avatar pictográfico. No se solicitan apellidos, fechas de nacimiento, correos, fotografías ni datos de contacto.

La persona usuaria es responsable de no introducir datos personales identificativos de menores en campos de texto libres (por ejemplo, escribir el nombre completo de un menor en el nombre de un cuento o en una actividad del horario). La app no filtra ese contenido porque todo permanece en el dispositivo.

## 6. Zona de adultos y código de acceso

La zona de adultos (modo padre) protege el control parental, las métricas de uso y los documentos legales.

- El código tiene cuatro dígitos y se guarda transformado mediante una función de derivación de claves con sal aleatoria (PBKDF2-HMAC-SHA256 con la librería `cryptography`). El código en claro no se almacena ni se registra en ningún archivo.
- Es imposible recuperar el código olvidado desde el propio dispositivo: si se olvida, la única opción es restablecer los datos de la aplicación desde la configuración de Android o reinstalarla, lo que borrará también el progreso local.
- Tras cinco intentos fallidos consecutivos, la app impone una espera de 60 segundos. El contador de intentos se conserva entre sesiones.
- El desbloqueo mediante huella o rostro es opcional y sustituye teclear el código; el código sigue siendo el mecanismo base y puede usarse siempre.

La persona adulta responsable es responsable de custodiar el código.

## 7. Pictogramas y contenidos de terceros

BlueTalk incluye símbolos de terceros con licencia abierta. El listado completo, con autoría y licencia de cada set, se muestra en la pantalla de créditos dentro de Ajustes. Mientras no se indique lo contrario en esa pantalla, los símbolos se distribuyen bajo las licencias Creative Commons que allí se citan (Mulberry Symbols CC BY-SA 4.0 y Twemoji CC BY 4.0), y su uso comercial está permitido por sus titulares dentro de los términos de dichas licencias.

Los cuentos, textos y actividades incluidos son creaciones propias de este proyecto o contenido de demostración.

## 8. Comunicación, bienestar y límites de la información mostrada

BlueTalk ofrece ayudas a la comunicación, rutinas y seguimiento de bienestar. Con carácter específico:

- Las observaciones automáticas de la zona de adultos son orientativas y se calculan con reglas deterministas sobre datos locales. No constituyen diagnóstico clínico ni sustituyen a un profesional sanitario o educativo.
- Los recordatorios de bienestar y las actividades de horario no son dispositivos médicos, no supervisan tratamiento alguno y no emiten alertas clínicas.
- Si la persona usuaria considera que el menor necesita evaluación o atención, debe acudir a los profesionales correspondientes: pediatra, logopeda, psicólogo o el equipo educativo.

La app no está diseñada para emergencias. Ante una situación de emergencia debe llamarse al servicio de emergencias local.

## 9. Conductas prohibidas

Al usar BlueTalk no está permitido:

- Extraer, revender o redistribuir los pictogramas fuera de los términos de sus licencias.
- Real ingeniería inversa salvo en la medida en que la ley aplicable lo permita de forma irrenunciable.
- Usar la app para recopilar datos de menores con fines comerciales, publicitarios o de perfilado.
- Suplantar la identidad de terceros en los campos de texto de la app.

## 10. Propiedad intelectual

El código fuente, el diseño, los textos originales y la estructura de BlueTalk pertenecen al desarrollador, sin perjuicio de los derechos de terceros sobre los símbolos y fuentes que se citan en los créditos. La aceptación de estos términos no transmite ningún derecho de propiedad intelectual; concede únicamente una licencia limitada, revocable y no transferible para uso personal y no comercial de la app en el dispositivo donde está instalada.

## 11. Privacidad

El tratamiento de datos personales se describe en la Política de privacidad de BlueTalk, que se acepta junto con estos términos y forma parte indivisible del acuerdo. La app no incluye publicidad ni SDK de análisis.

## 12. Servicios implicados en el funcionamiento

Para su trabajo, la app depende de funciones del propio sistema Android:

- El sintetizador de voz del sistema para hablar pictogramas. Su calidad y disponibilidad dependen de las voces instaladas en el teléfono.
- Notificaciones locales, si la persona usuaria las autoriza.
- Almacenamiento local del dispositivo.

No se incorporan SDK de publicidad, analítica o redes sociales en esta versión. Google Play Store actúa como canal de distribución y sus condiciones de compra y descarga se aplican a la descarga de la app.

## 13. Actualizaciones y cambios en estos términos

El desarrollador puede actualizar la app y estos términos. Cada versión de los términos lleva número y fecha; la versión vigente se muestra en la zona de adultos junto a la fecha de aceptación.

Cuando los cambios sean sustanciales, la app pedirá volver a aceptar los términos actualizados. El uso continuado tras la aceptación de una versión nueva implica la adhesión a esa versión. Si la persona usuaria no está de acuerdo, debe dejar de usar la app.

## 14. Disponibilidad y mantenimiento

Esta es una versión de prueba: puede contener errores, perder compatibilidad con actualizaciones del sistema o cambiar de contenido sin aviso previo. El desarrollador no garantiza disponibilidad ininterrumpida ni conservación del contenido si el almacenamiento local del teléfono se pierde o se restablece.

## 15. Responsabilidad

En la máxima medida permitida por la ley aplicable, el desarrollador no responde de:

- Daños derivados del uso de la app en lugar de buscar la evaluación profesional adecuada.
- Pérdida de datos locales causada por fallos del dispositivo, restablecimiento de fábrica o desinstalación.
- Incompatibilidad del teléfono con la app en dispositivos fuera del rango soportado.

Ninguna disposición de estos términos limita la responsabilidad que no pueda excluirse por ley.

## 16. Ley aplicable y resolución de controversias

Estos términos se rigen por la legislación del país donde se instale la app. Ante cualquier desacuerdo, la persona usuaria puede escribir al correo de contacto indicado en el apartado 1 para buscar una solución directa antes de acudir a la autoridad competente.

## 17. Contacto

Correo: demo@bluetalk.app (dirección de demostración de este proyecto).
Última actualización de este documento: 13 de octubre de 2026, versión 1.0.0.
