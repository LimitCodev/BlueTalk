# Recorrido funcional completo (2026-11-09)

Rama `feat/modular-freemium-aws`. APK de depuración de la edición `play`,
instalación limpia en el emulador `bluetalk_gama_baja` (API 28, 720×1280).
Se recorrió la app como usuario, tocando la pantalla.

## Defectos encontrados y corregidos

| # | Defecto | Causa | Cómo se comprobó |
|---|---|---|---|
| 1 | La voz puede no sonar en Android 11 o superior | El manifiesto no declaraba `android.intent.action.TTS_SERVICE` en `<queries>`; nunca estuvo en el historial | `aapt2` encuentra la declaración en el APK; test en `manifiesto_test.dart`. **El sonido no se ha oído: ver NO VERIFICADO** |
| 2 | «Volver» dentro de un cuento no salía: solo se podía usar un cuento hasta cerrar la app | `copyWith(storyId: null)` no cambia nada, porque `null` significa «conservar» | Test en rojo antes del arreglo y emulador |
| 3 | «Elegir otro nivel» reiniciaba el nivel en lugar de abrir el selector | La misma causa, con `nivel: null` | Test en rojo antes del arreglo y emulador |
| 4 | Atrás en una vista de Rutinas saltaba a Comunicar | `manejarAtras` no contemplaba las vistas internas de Rutinas | Test en rojo antes del arreglo y emulador |
| 5 | «Probar la voz» decía solo «sube el volumen» aunque no hubiera voz | La pantalla no consultaba si hay voz en español | Test en rojo antes del arreglo y emulador: muestra el aviso y abre `Text-to-speech output` de Android |
| 6 | Tras instalar una voz seguía constando que no había | La lista vacía de idiomas quedaba guardada para toda la sesión | Revisión del código; sin test propio |

## Recorrido sin defectos

- Primer uso: apodo y entrada al comunicador.
- Comunicador: tablero de palabras básicas, frase, guardar y Mis mensajes.
- Memoria: nivel 1 completo y desbloqueo del nivel 2.
- Cuentos: lectura, tarea final y cuento marcado como completado.
- Artista: dibujar, guardar y ver en Mis dibujos.
- Rutinas: marcar actividad, Primero y luego, Mi día, Mi colegio y estadísticas.
- Zona de adultos: términos, PIN nuevo, PIN al volver a entrar, informes,
  Control, Salud y Legal.
- Los datos siguen ahí tras cerrar la app a la fuerza y abrirla.
- `logcat` sin errores de Flutter en todo el recorrido.

## Verificación final

- `flutter analyze`: sin problemas.
- `flutter test`: 409/409.
- `flutter build apk --debug --flavor play`: correcto, Kotlin incluido.

## NO VERIFICADO

- **Que la voz suene.** La imagen del emulador no trae motor de voz
  (`not bound to TTS engine`) y es API 28, donde la regla de Android 11 no
  aplica. Hace falta un teléfono con Android 11 o superior, o una imagen del
  emulador con motor de voz.
- La edición `directa` no se recorrió; comparte `main` con estos arreglos.
- AAB firmado: se genera fuera del sandbox con `scripts/build-aab.sh`.

## Sin hacer: funciones que faltan

Son funciones nuevas, no defectos, y las dos primeras dependen de una decisión
sobre dependencias:

- Fotos propias en pictogramas (plan 11 §2.3).
- Copia de seguridad: exportar e importar (plan 11 §2.4).
- Selector de voz del sistema (plan 11 §2.4).
- Modo niño con inicio restringido (plan 12, fases 1 a 3).
