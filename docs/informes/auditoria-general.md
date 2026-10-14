# BlueTalk — Auditoría general (14-oct-2026)

**Alcance:** código en `lib/` (80 archivos, ~10 200 líneas), `test/` (29 archivos), `android/`, `assets/`, `docs/` y planes.
**Objetivo evaluado:** un APK funcional para niños autistas y sus familias, con camino a Play Store.

## 1. Resumen ejecutivo

La base es buena: arquitectura limpia, accesibilidad cuidada, modo calma, 100 % offline y un gate de padres bien diseñado. **Pero hoy la app no es la que describen los planes.** Hay tres problemas que hay que cerrar antes de hablar de Play Store:

1. **Casi todo el trabajo de la "Ola 2" no está conectado ni commiteado.** Rutinas, salud, entorno y modo padre existen como código, pero el router sigue mostrando placeholders. Además, esos archivos están sin commitear (`git status` los lista como `??`).
2. **Persistencia más débil de lo documentado.** No se usa Drift ni Supabase (siete dependencias sin ningún `import`). Los cambios del horario se pierden al cerrar la app.
3. **Release no publicable.** Firma con claves de debug, icono por defecto de Flutter y sin documentación de Play (`docs/play/` no existe).

### Resultados de las comprobaciones

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | ✅ 0 problemas |
| `flutter test` | ⚠️ 123 pasan, **11 fallan** (todas en `test/rutinas/`) |
| `flutter build apk --debug` | ✅ compila (38 s, 210 MB por ser debug) |
| Release, AAB, emulador gama baja, perfilado | ❌ no se probó (ver §8) |
| Ejecución en dispositivo | ❌ no se probó: solo había escritorio Linux conectado |

## 2. Lo que funciona bien (conservar)

- **Capas de datos por contratos** (`lib/data/contracts/repos.dart`): permite cambiar el almacenamiento sin tocar pantallas.
- **Gate de padres** (`lib/features/padre/gate/pin_store.dart`): PIN con sal aleatoria, PBKDF2-SHA256, comparación en tiempo constante, bloqueo persistente tras 5 fallos, biometría opcional.
- **Lectura tolerante a corrupción** de preferencias (`_tryDecodeObject`): un JSON roto no impide arrancar.
- **Modo calma** real: grises + animaciones apagadas + respeta "eliminar animaciones" del sistema (`lib/app/app.dart`).
- **TTS sin autoplay**, con aviso único si falta voz en español (`tts_service.dart`).
- **Accesibilidad:** objetivos táctiles ≥48 dp, contrastes verificados con test, `Semantics` literal ("Recreo, hecha"), pruebas con `accessibility_tools`.
- **Lenguaje literal y disclaimer** "no es diagnóstico" en las observaciones.

## 3. Hallazgos críticos (bloquean "funcional")

### C1. Pantallas construidas pero no conectadas
- `lib/app/router.dart:62` — la pestaña **Rutinas** muestra `_TabContent('Rutinas', … 'próximamente')`. `RutinasScreen` (con horario, estadísticas, bienestar y colegio) existe pero nadie la usa.
- `lib/app/router.dart:88` — `/padre` muestra "Se activará con tu PIN". `PadreScreen` existe.
- **No hay ningún botón en la app que lleve a `/padre`.** Un padre no puede entrar.
- `JuegosGate` (límite diario de juegos) no envuelve `/home/aprender`, así que **el control parental de tiempo no se aplica**. Tampoco se usa `AvisoTiempoJuegos`.
- Los bloqueos "juegos" y "entorno" del panel de control no tienen efecto: `entorno` ni siquiera se consulta.

**Arreglo:** 4 cambios en `router.dart` (usar `RutinasScreen`, `PadreScreen`, envolver con `JuegosGate`, leer `bloqueosProvider.entorno`) y un acceso discreto al modo padre en Ajustes. Después, commitear las carpetas sin seguimiento.

### C2. Trabajo sin commitear
Hay 23 rutas sin seguimiento (`lib/features/padre/**`, `lib/features/rutinas/**`, `docs/legal/**`, `test/rutinas/`, etc.). Si se pierde el disco, se pierde la Ola 2 completa. **Commitear ya**, aunque sea en una rama.

### C3. El horario no persiste
`SeedScheduleRepo` (`lib/data/local/mock_repos.dart`) guarda las ediciones solo en un `Map` en memoria. Al cerrar la app se pierde cualquier actividad creada, editada o quitada. Un padre que arma la rutina del niño lo perdería cada día. **Es el fallo más grave desde el punto de vista del usuario.**
**Arreglo mínimo:** serializar a `SharedPreferences` como ya hacen `PrefsGameProgressRepo` y `PrefsUsageRepo`.

### C4. Dependencias declaradas pero sin uso
Cero `import` de: `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `flutter_secure_storage`, `supabase_flutter`, `connectivity_plus`, `http`, `path_provider`, `flutter_local_notifications`, `timezone`.
- Aumentan el tamaño del APK y la superficie de revisión de Play (cada plugin es código nativo).
- **Los recordatorios de rutina prometidos no existen:** sin `flutter_local_notifications` activo, nada avisa al niño de la próxima actividad.
- `README.md` y el plan dicen "Drift" y "Supabase desde el inicio"; el código usa `SharedPreferences`.

**Decisión recomendada:** quitar las que no se vayan a usar en el MVP (`supabase_flutter`, `connectivity_plus`, `http`, `flutter_secure_storage` si no se mueve el PIN). Dejar `drift` solo si se migra de verdad (ver M1).

### C5. 11 tests en rojo (`test/rutinas/`)
- Nueve fallan porque **`"Mi día"` aparece dos veces** en pantalla (`rutinas_screen.dart:56` y `horario_view.dart:172` / `salud_screen.dart:72` / `estadisticas_view.dart:104`) y el test espera una. Es un desajuste test↔pantalla, no un fallo de lógica.
- Otros dos (`horario_test.dart` "Recreo: hecha", `editor_horario_test.dart` "Actividades quitadas") **no están diagnosticados**; pueden ser consecuencia de lo anterior o un problema real de la interacción. Hay que revisarlos a mano.
- `test/padre/` está **vacío**: el código de seguridad (PIN, bloqueo, legal, límites) no tiene ningún test.

## 4. Hallazgos importantes

### M1. Eventos de uso: tope compartido de 200
`PrefsUsageRepo` conserva solo los últimos 200 eventos **de todos los tipos**. Cada toque a un pictograma crea un evento (`comunicador_screen.dart:523`). En una sesión de comunicación normal, los `juego_fin` de hoy se descartan.
Consecuencias: el límite diario de juegos **cuenta de menos** (el niño puede jugar más de lo permitido) y las métricas del padre son poco fiables. **Arreglo:** contadores agregados por día (clave `AAAA-MM-DD`) en lugar de una lista de eventos, o pasar a Drift con purga por fecha.

### M2. Seguridad del PIN
- 4 dígitos = 10 000 combinaciones. Con 5 intentos por minuto, ~33 horas en el peor caso. Aceptable para controlar a un niño, **no** contra alguien con acceso al teléfono desbloqueado y paciencia.
- Huella y sal en `SharedPreferences` (texto plano en el almacenamiento de la app). Quien tenga root o copia de seguridad puede leerlas y probar PINs sin límite (el bloqueo es solo de la interfaz). Mover a `flutter_secure_storage` (ya está declarado) aporta poco con 4 dígitos; **subir a 6 dígitos y 100 000+ iteraciones** aporta más.
- No hay "olvidé mi PIN". Sin recuperación, el padre debe borrar datos de la app (y pierde el progreso). Hay que decidir y documentar el procedimiento.
- Android: añadir `android:allowBackup="false"` (o reglas de exclusión) para que el PIN y los datos del niño no salgan en copias en la nube.

### M3. Contenido insuficiente para ser "una joya"
- **42 pictogramas, 7 categorías, 3 cuentos, 6 actividades de horario.** Las apps de referencia (en `research_notes/`) tienen cientos o miles.
- La lista de 218 palabras de Soto & Cooper 2021 está investigada (`research_notes/datos-publicos/`) pero **no se aplicó** al seed.
- `assets/fonts/` está vacío. Los pictogramas son SVG sueltos de `muestra/`; falta la carpeta definitiva de Mulberry.

### M4. Legal y licencias
- Los Términos dicen "licencia **no comercial**" (`textos_legales.dart:126`) mientras el plan contempla Premium. Hay que alinear el modelo de negocio con el texto antes de publicar.
- La pantalla de créditos lista Mulberry; **no encontré a Twemoji** (que el texto legal cita). Verificar y completar.
- CC BY-SA 4.0 exige atribución y compartir igual **de las adaptaciones de los pictogramas**. Si se recolorean o modifican, deben publicarse bajo la misma licencia.
- Los textos legales no son revisión de abogado. Para una app con datos de menores se recomienda una revisión profesional (LOPD Perú / COPPA / GDPR-K según los países de destino).

### M5. Release no publicable (`android/app/build.gradle.kts`)
- `signingConfig = signingConfigs.getByName("debug")` — **Play rechaza este AAB.** Crear un keystore de subida y `key.properties` (ya ignorados en `.gitignore`).
- Sin `isMinifyEnabled` / `isShrinkResources`: APK más grande.
- Icono de lanzador por defecto de Flutter; etiqueta `bluetalk` en minúsculas (`AndroidManifest.xml`).
- No existe `docs/play/` ni los scripts de `scripts/` (solo `.gitkeep`). No hay CI (`.github/` no existe).

## 5. Hallazgos menores

- `README.md` dice "Fase de planificación"; el proyecto ya compila y tiene 80 archivos. Actualizar.
- El flujo de onboarding **no permite empezar sin apodo** (`_canStart` exige texto) aunque el comentario dice "con o sin apodo". Para un niño con comunicación limitada, empezar sin apodo debería ser posible.
- La pestaña Rutinas del shell sigue como "próximamente" aunque el plan la da por hecha.
- `lib/features/padre/control/juegos_gate.dart` y `padre_screen.dart` documentan "el coordinador debe cablear esto": hay un hilo suelto de trabajo que nadie asumió.
- `dart` en el PATH apunta a `/opt/dart-sdk`, no al SDK de Flutter (aviso de `flutter doctor`). Pone en riesgo versiones distintas entre `dart` y `flutter`.
- Sin `flutter_lints` extra ni reglas de `analysis_options.yaml` más estrictas (p. ej. `prefer_const_constructors`, `avoid_print`).

## 6. Qué no verifiqué (para ser honesto con el alcance)

- No ejecuté la app en un dispositivo ni emulador; todo lo funcional se basa en lectura de código y tests.
- No leí línea a línea los juegos (`memoria`, `cuentos`, `artista`), `ajustes_screen.dart`, `salud_screen.dart` ni `editor_horario_view.dart`; los tests de juegos y comunicador (que pasan) son mi evidencia de que funcionan.
- No comprobé el funcionamiento de "guardar dibujo en dispositivo" del artista (no hay `path_provider` en uso; hay que ver cómo se guarda).
- No compilé en modo release ni medí tamaño, RAM ni arranque en frío.
- No evalué el texto completo de los documentos legales.

## 7. Plan recomendado (priorizado)

### Fase 0 — "Que funcione" (1–2 días)
1. Commitear todo lo sin seguimiento (C2).
2. Cablear `RutinasScreen`, `PadreScreen`, `JuegosGate` y bloqueo de entorno en `router.dart`; añadir acceso a modo padre desde Ajustes (C1).
3. Persistir el horario en `SharedPreferences` (C3).
4. Arreglar los 11 tests (C5) y añadir tests básicos de `PinStore`, `LimiteJuegos` y `PadreController`.
5. Contadores diarios en lugar de lista de 200 eventos (M1).

### Fase 1 — "Que sea confiable" (1 semana)
6. Quitar dependencias sin uso o implementarlas (C4). Implementar **recordatorios locales** con `flutter_local_notifications` (es el valor central de las rutinas visuales).
7. PIN de 6 dígitos + más iteraciones + `allowBackup=false` (M2). Definir recuperación del PIN.
8. Permitir empezar sin apodo; probar en un teléfono real de gama baja.
9. Perfilar: arranque <3 s, RAM <150 MB, grilla de SVG sin tirones (el plan ya identifica el riesgo con `flutter_svg`).

### Fase 2 — "Que sea una joya" (el diferenciador)
Lo que hace que una familia la descargue en lugar de otra:

| Idea | Por qué importa | Esfuerzo |
|---|---|---|
| **Vocabulario nuclear de 200+ palabras** en posiciones fijas (Soto & Cooper ya investigado) | Planificación motora: las palabras no cambian de sitio. Es el estándar en AAC | M |
| **Primero–Luego** y horario visual con avisos suaves | Reduce ansiedad ante transiciones | S |
| **Pictogramas y fotos propias** (cámara/galería, solo en el dispositivo) | Los niños aprenden con su propia mamá, su casa, su juguete | M |
| **Barra de frase con voz natural** (ajustar velocidad/voz; opción de grabar la voz del padre) | La voz robótica es la queja más común en las opiniones recopiladas | M |
| **Copia de seguridad / exportar** (archivo local o PDF para terapeuta) | Evita perder años de configuración; útil para el equipo clínico | M |
| **Varios perfiles** (hermanos, aula) | Casos reales de uso familiar y escolar | M |
| **Historias sociales** editables | Ya hay 3 cuentos; permitir que el padre cree las suyas | M |
| **Sin anuncios, sin cuenta, sin internet** como promesa visible | Confianza de padres y requisito de Families Policy | — |

### Fase 3 — Play Store
10. Keystore de subida, `key.properties`, `flutter build appbundle --release --obfuscate --split-debug-info`.
11. Icono adaptativo, nombre "BlueTalk", capturas, descripción sin afirmaciones médicas.
12. **Política de privacidad alojada en una URL pública** (Play la exige; hoy solo existe en la app y en `docs/legal/`).
13. Formulario de **Seguridad de los datos** (declarar "no se recopilan datos" si se mantiene 100 % local) y de **Familias** (público objetivo con menores: sin anuncios de terceros, sin permisos innecesarios).
14. Pruebas cerradas (12+ testers durante 14 días si la cuenta es personal nueva), probar en Android 7 con 1–2 GB.
15. Alinear los Términos con el modelo de negocio (gratis o Premium) antes de enviar.

## 8. Riesgos y lo que falta decidir

- **Decisión:** ¿el MVP se queda en `SharedPreferences` o se migra a Drift? Recomiendo quedarse y quitar Drift, porque el volumen de datos es pequeño y la migración añade riesgo sin beneficio visible.
- **Decisión:** ¿Supabase entra en el MVP? Recomiendo **no**: añade la obligación de política de datos de menores, consentimiento verificable y revisión más estricta de Play.
- **Decisión:** longitud del PIN y procedimiento de recuperación.
- **Decisión:** modelo de negocio (afecta a la licencia de los pictogramas y a los Términos).
- **Riesgo:** una app de salud/autismo no debe sugerir diagnósticos. El disclaimer actual es correcto; mantenerlo en el listing de Play.
- **Riesgo:** sin pruebas en un teléfono real de gama baja, los objetivos de rendimiento son solo un deseo.
