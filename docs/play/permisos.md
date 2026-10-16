# Permisos de Android y su justificación (plan 11 §0.1.7)

Cada permiso que declara la app en
`android/app/src/main/AndroidManifest.xml`, para qué existe y dónde lo
experimenta el usuario. `flutter_local_notifications` trae en su propio
manifiesto `POST_NOTIFICATIONS` y `VIBRATE` (se fusionan al compilar); la app
los declara también de forma explícita para que queden auditados aquí.

| Permiso | Para qué lo necesita BlueTalk | Dónde lo ve el usuario |
|---|---|---|
| `RECEIVE_BOOT_COMPLETED` | Reprogramar los avisos del horario tras reiniciar el móvil: el plugin guarda los avisos y su receptor de arranque los repone. | No muestra diálogo: es un permiso normal al instalar. |
| `POST_NOTIFICATIONS` (Android 13+) | Mostrar los avisos diarios «Es hora de: X.» del horario. | Solo desde Ajustes → Recordatorios → «Activar recordatorios», siempre después de una explicación literal. Nunca al arrancar (plan 1.1). |

Receptores declarados (README de `flutter_local_notifications` 22.x):
`ScheduledNotificationReceiver` y `ScheduledNotificationBootReceiver`, con las
acciones `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`, `QUICKBOOT_POWERON` y
`com.htc.intent.action.QUICKBOOT_POWERON`.

La verificación en dispositivo (avisos y tras reinicio) queda registrada en
`docs/informes/fase1-evidencia.md`.
