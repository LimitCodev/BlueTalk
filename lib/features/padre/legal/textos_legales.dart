// Textos legales de la zona de adultos, en espejo de `docs/legal/*.md`.
//
// Los documentos maestros viven en `docs/legal/` (rutas dueñas de este
// agente). Como `pubspec.yaml` está congelado en la Ola 2 y `docs/legal/`
// no puede declararse como asset, la app lleva aquí el mismo texto para
// renderizarlo sin red ni carga de assets. Si el pubspec se desbloquea, el
// pendiente es leer los .md desde `rootBundle` y borrar este espejo.

/// Parser de los .md: `## ` → encabezado, `- ` → vineta, resto → párrafo.
/// Los `**` de énfasis se quitan al render (la app no necesita negritas).
List<LineaLegal> parsearLineas(String texto) {
  final lineas = <LineaLegal>[];
  for (final cruda in texto.split('\n')) {
    final linea = cruda.trim();
    if (linea.isEmpty) continue;
    if (linea.startsWith('# ')) continue; // el título lo pone la pantalla
    if (linea.startsWith('## ')) {
      lineas.add(LineaLegal(LineaLegalTipo.encabezado, linea.substring(3)));
    } else if (linea.startsWith('- ')) {
      lineas.add(LineaLegal(LineaLegalTipo.vineta, linea.substring(2)));
    } else {
      lineas.add(LineaLegal(LineaLegalTipo.parrafo, linea));
    }
  }
  return lineas;
}

class LineaLegal {
  const LineaLegal(this.tipo, this.texto);
  final LineaLegalTipo tipo;
  final String texto;
}

enum LineaLegalTipo { encabezado, vineta, parrafo }

String _limpiar(String texto) => texto.replaceAll('**', '');

const versionLegal = '1.0.0';
const fechaEfectivaLegal = '13 de octubre de 2026';
const correoContactoLegal = 'demo@bluetalk.app';

final String terminosYCondiciones = _limpiar(r'''
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
- Esta app no realiza evaluaciones ni pruebas de detección («screening»): no clasifica a las personas ni indica si tienen alguna condición.
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
Última actualización de este documento: 13 de octubre de 2026, versión 1.0.0.''');

final String politicaDePrivacidad = _limpiar(r'''
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
Última actualización: 13 de octubre de 2026, versión 1.0.0.''');
