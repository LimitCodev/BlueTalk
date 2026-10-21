# Permisos de Android y su justificación (plan 11 §0.1.7 y plan 14)

Cada permiso que declara la app en
`android/app/src/main/AndroidManifest.xml`, para qué existe y dónde lo
experimenta el usuario. `flutter_local_notifications` trae en su propio
manifiesto `POST_NOTIFICATIONS` y `VIBRATE` (se fusionan al compilar); la app
los declara también de forma explícita para que queden auditados aquí.

| Permiso | Para qué lo necesita BlueTalk | Dónde lo ve el usuario |
|---|---|---|
| `RECEIVE_BOOT_COMPLETED` | Reprogramar los avisos del horario tras reiniciar el móvil: el plugin guarda los avisos y su receptor de arranque los repone. | No muestra diálogo: es un permiso normal al instalar. |
| `POST_NOTIFICATIONS` (Android 13+) | Mostrar los avisos diarios «Es hora de: X.» del horario y el aviso permanente del filtro de páginas. | Solo desde Ajustes → Recordatorios → «Activar recordatorios», siempre después de una explicación literal. Nunca al arrancar (plan 1.1). |
| `INTERNET` | Reenviar las consultas DNS permitidas al servidor DNS de la red cuando el adulto activa el filtro. Sin el filtro, la app no hace peticiones de red. | No muestra diálogo. Se explica en la pantalla del filtro y en la política de privacidad. |
| `ACCESS_NETWORK_STATE` | Leer los servidores DNS de la Wi-Fi o de los datos móviles para reenviar las consultas permitidas, y detectar si el DNS privado de Android está activo. | No muestra diálogo. La pantalla del filtro avisa si el DNS privado puede saltarse el bloqueo. |
| `FOREGROUND_SERVICE` | Mantener la VPN local en primer plano mientras filtra, con un aviso permanente que el usuario puede ver. | El aviso «Filtro de páginas activo» aparece en la barra de notificaciones mientras el filtro está encendido. |
| `FOREGROUND_SERVICE_SPECIAL_USE` (Android 14+) | Declarar el tipo de servicio de uso especial que corresponde a una VPN local de filtrado. | No muestra diálogo; se justifica en la ficha de Play. |

## Servicio VPN (plan 14)

`FiltroWebVpnService` se declara en el manifiesto con:

- `android:exported="false"`: ninguna otra app puede arrancarlo;
- `android:permission="android.permission.BIND_VPN_SERVICE"`: solo Android
  puede vincularlo como VPN;
- `android:foregroundServiceType="specialUse"` y la propiedad
  `android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE` con la explicación
  «Filtro DNS local para el control parental; no inspecciona tráfico».

La app **no** pide `QUERY_ALL_PACKAGES`, accesibilidad, administrador de
dispositivos ni permiso para dibujar sobre otras apps. La VPN solo recibe las
consultas dirigidas a su propio DNS (`10.111.222.1` y su equivalente IPv6) y
no enruta el resto del tráfico. El consentimiento de VPN lo concede el adulto
con el diálogo propio de Android.

Para Google Play hay que declarar el uso de `VpnService` en Play Console y
completar la sección de seguridad de datos. La app no vende ni comparte datos;
las consultas DNS permitidas salen al servidor de la red, no a un servidor del
desarrollador.

## Receptores declarados

Receptores de `flutter_local_notifications` 22.x:
`ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver`, con las
acciones `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON` y
`com.htc.intent.action.QUICKBOOT_POWERON`.

## Copias de seguridad desactivadas (plan 11 §1.2.6)

`android:allowBackup="false"` y `android:fullBackupContent="false"` en el
manifiesto, más `android:dataExtractionRules` apuntando a
`res/xml/data_extraction_rules.xml` (un archivo sin reglas, válido desde
Android 12): nada de la app se copia a la nube de Google ni se traspasa con
«transferir datos». Los datos del menor permanecen solo en el dispositivo,
como exigen los principios de producto.

La verificación en dispositivo (avisos y tras reinicio) queda registrada en
`docs/informes/fase1-evidencia.md`; la del filtro, en
`docs/informes/filtro-web-evidencia.md`.
