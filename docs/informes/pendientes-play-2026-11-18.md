# Pendientes para publicar BlueTalk en Google Play

**Fecha:** 18 de noviembre de 2026  
**Alcance:** edición `play` (AAB). No incluye la edición `directa` salvo donde se indica.  
**Regla de este documento:** lo verificado se dice como verificado; lo que no se pudo comprobar queda como **NO VERIFICADO**. Este documento no crea cuentas, claves ni publica nada.

---

## Veredicto

La app **todavía no se puede subir a Play Store**, pero el bloqueo principal no es el código. El build de release compila, el análisis Dart está limpio y los requisitos técnicos de Android se cumplen. Faltan la **clave de firma real**, la **política de privacidad publicable** y el **trámite de Play Console** (cuenta, declaraciones y prueba cerrada).

| # | Falta | Severidad | Responsable |
|---|---|---|---|
| 1 | Keystore de firma y AAB real | **P0** | Dueño |
| 2 | Política de privacidad, correo y URL pública | **P0** | Dueño + código |
| 3 | Cuenta de Play Console y Play App Signing | **P0** | Dueño |
| 4 | Declaraciones de Play Console | **P0** | Dueño |
| 5 | Prueba cerrada de 12 testers × 14 días | **P0** | Dueño |
| 6 | Ficha: URL, correo y capturas actuales | **P0/P1** | Dueño + código |
| 7 | Repositorio limpio y commit/tag de release | **P0** | Código |
| 8 | Prueba del AAB en dispositivo y rendimiento | **P1** | Código |

---

## Resumen cuantitativo y conclusión

No hay un único número de “errores”: hay que separar **defecto**, **requisito externo**, **decisión** y **verificación**. Con ese criterio, el informe contiene:

| Unidad de conteo | Número | Interpretación |
|---|---:|---|
| Errores de código que impidan compilar | **0** | `analyze` limpio, 456 tests y AAB de prueba compilado |
| Áreas que bloquean la publicación | **7 P0 + 1 P1** | Firma, legal, cuenta, declaraciones, prueba cerrada, ficha, repo y QA |
| Acciones concretas de la checklist | **66** | 43 P0 + 7 P0/P1 + 16 P1 |
| Acciones opcionales o “no aplica” | **7** | 3 declaraciones “no aplica” + 4 opcionales |
| Acciones obligatorias restantes | **59** | El trabajo real para cerrar los 8 bloques |

**Conclusión:** la app está técnicamente cerca, pero **no es publicable hoy**. El camino crítico no es Dart: es la firma, la política de privacidad publicable y el trámite de Play Console, con la prueba cerrada de 12 testers/14 días como plazo más largo. Los 66 ítems no son 66 errores: son las acciones que cierran 8 causas raíz. No se deben sumar ambos números.

**Metodología aplicada:**

1. **Definir la unidad antes de contar:** un defecto verificado no es una tarea, un trámite externo no es un bug y una decisión del dueño no es un error.
2. **Separar hallazgo, evidencia, acción, responsable y criterio de terminado.** Cada P0 del informe tiene archivo o comando que lo respalda.
3. **Agrupar por causa raíz** para no contar dos veces el mismo problema (por ejemplo, el correo ficticio aparece en la política y en la ficha, pero es una sola causa).
4. **Priorizar por impacto, no por volumen:** 7 bloqueadores P0 impiden publicar; 66 tareas no tienen el mismo peso.
5. **Distinguir “no verificado” de “fallo”.** La falta de prueba en dispositivo es una incertidumbre, no un defecto demostrado.
6. **Usar criterios de terminado verificables:** URL que abre, AAB que firma, test que pasa, captura que representa la UI actual.
7. **Reauditar al cerrar cada bloque** y actualizar el informe; no contar como hecho lo que solo se compiló.
8. **No usar el número de errores como métrica de progreso.** La métrica útil es “bloqueadores P0 cerrados con evidencia”.

---

## 1. Firma y AAB real — P0

### Estado verificado

- `android/key.properties` existe (permisos `600`) y apunta a:

  ```text
  /home/josue/keystores/bluetalk-release.keystore
  ```

- `~/keystores/` está vacío: **el keystore no está en esta máquina**.
- `./scripts/build-aab.sh` se detiene antes de compilar:

  ```text
  BLOQUEADO: el keystore no existe en '/home/josue/keystores/bluetalk-release.keystore'.
  ```

- Para separar “no compila” de “falta la clave”, se compiló una copia temporal del árbol actual con una **clave desechable**:
  - AAB de **55,9 MB**;
  - `jarsigner -verify` correcto;
  - librerías nativas alineadas a 16 KB;
  - **ese AAB no sirve para Play** y se borró al terminar.

### Qué falta

- [ ] Restaurar `bluetalk-release.keystore` desde la copia de seguridad del dueño.
- [ ] Comprobar que la contraseña y el alias funcionan:

  ```bash
  keytool -list -v -keystore ~/keystores/bluetalk-release.keystore -alias bluetalk
  ```

- [ ] Anotar la huella SHA-256 de la clave y guardarla junto al keystore, fuera del repositorio.
- [ ] Ejecutar `./scripts/build-aab.sh` y verificar:
  - `jarsigner -verify` del AAB;
  - `versionCode`, `versionName`, `targetSdk 36`, `minSdk 24`;
  - 16 KB en las librerías nativas;
  - que el AAB incluya `arm64-v8a`;
  - `dist/simbolos/<versión>/` con los símbolos Dart;
  - `build/app/outputs/mapping/playRelease/mapping.txt` copiado a un lugar seguro.
- [ ] Probar ese AAB concreto desde prueba interna, no solo un APK debug.

### Decisión del dueño

Si el keystore se perdió:

- si **nunca** se subió nada a Play, se puede generar una clave nueva;
- si ya existe una app publicada, hay que usar la recuperación de clave de subida de Play Console;
- sin la clave no se pueden firmar futuras versiones.

---

## 2. Política de privacidad, correo y URL — P0

### Estado verificado

- No hay URL pública de la política.
- `demo@bluetalk.app` aparece en `docs/legal/PRIVACIDAD.md`, `docs/legal/TERMINOS_Y_CONDICIONES.md` y en `lib/features/padre/legal/textos_legales.dart`. Es una dirección de demostración, no un correo atendido.
- `docs/legal/PRIVACIDAD.md` tiene el **§5 “Voz y otras funciones del sistema” vacío**. La copia in-app sí tiene texto: los dos espejos no coinciden.
- `infra/aws/sitio/index.html` enlaza a `privacidad.html` y `terminos.html`, pero esos archivos **no existen** en `infra/aws/sitio/`. Si se despliega así, los enlaces dan 404.
- El texto in-app filtra las líneas de VPN para la edición `play` mediante `lib/core/plataforma/edicion.dart`. El Markdown que se publicaría no incluye la explicación de voz/TTS que sí está en la app: el §5 está vacío.
- “LimitCodev” es un alias; la política debe identificar al responsable legal.
- La versión legal actual es `1.2.0` (`versionLegal` en `lib/features/padre/legal/textos_legales.dart`).

### Qué falta

- [ ] Decidir el **correo real y atendido** de soporte/privacidad. No inventar uno.
- [ ] Decidir la **identidad legal** que figurará como responsable (nombre o entidad, no solo el alias).
- [ ] Crear la política específica de la edición Play:
  - sin VPN, sin acceso al uso y sin administrador de dispositivo;
  - con la explicación de la voz del sistema Android y de que el texto se pasa al sintetizador;
  - con la explicación de que los datos del menor se quedan en el teléfono;
  - con el correo real y la identidad legal.
- [ ] Rellenar el §5 del Markdown publicado con el texto de voz/TTS que ya existe en la app.
- [ ] Publicar `privacidad.html` y `terminos.html` en una URL HTTPS, pública, sin login y sin geobloqueo.
- [ ] Arreglar `infra/aws/sitio/` para que los enlaces no apunten a archivos inexistentes, o publicar desde otra carpeta que sí los incluya.
- [ ] Sincronizar el texto publicado con `textos_legales.dart`.
- [ ] Subir `versionLegal` a `1.3.0` (o la versión que corresponda) y forzar la nueva aceptación si el cambio es sustancial.
- [ ] Revisar la mención a **Twemoji** en README/Términos: no hay assets Twemoji en el proyecto y la pantalla de créditos solo lista Mulberry. O se usa y se acredita, o se retira la mención.
- [ ] Revisar los Términos de la edición `directa`: dicen que la app se distribuye por Google Play, pero ese APK se reparte fuera de Play.

El detalle operativo de correo, dominio, identidad y custodia de credenciales está en **§3 bis**.

### Criterio de terminado

Una persona puede abrir la URL de privacidad desde el listado de Play, leer una política completa y escribir al correo indicado. La política publicada y la que se ve en la app dicen lo mismo para la edición Play.

---

## 3. Cuenta de Play Console y Play App Signing — P0

### Estado

Según la documentación del repositorio, **no hay cuenta de desarrollador ni inscripción en Play App Signing**. No se ha verificado el estado real de Play Console porque este equipo no tiene acceso a la cuenta.

### Qué falta

- [ ] Crear la cuenta de desarrollador (25 USD, pago único; decisión del dueño).
- [ ] Completar identidad, dirección, teléfono y verificación en dos pasos.
- [ ] Verificar el dispositivo con la app Play Console.
- [ ] Inscribir la app en **Play App Signing**.
- [ ] Confirmar el `applicationId` definitivo: hoy es `com.limitcodev.bluetalk`.
- [ ] Confirmar que el nombre `BlueTalk` y el paquete están disponibles.
- [ ] Crear la app en Play Console y subir el primer AAB a **prueba interna**.

### Nota

Si la cuenta es personal y se creó después del 13-nov-2023, la prueba cerrada de 12 testers/14 días es obligatoria antes de producción. Si es de organización, exige entidad legal y D-U-N-S, que puede tardar 30 días o más.

---

## 3 bis. Cuentas, credenciales y contacto — P0

### Respuesta corta

BlueTalk **no tiene cuentas de usuario**: no hay registro, inicio de sesión ni sincronización. Por eso, la «cuenta de ayuda» que falta **no es una cuenta dentro de la app**: es un **buzón de soporte real y atendido** —más, si se decide, una página de ayuda/FAQ— y el correo que debe aparecer en Términos, Privacidad, ficha y Play Console.

Hoy `demo@bluetalk.app` es una dirección de demostración. Aparece **11 veces en 3 archivos que llegan al usuario**:

| Archivo | Líneas | Uso |
|---|---|---|
| `docs/legal/TERMINOS_Y_CONDICIONES.md` | 10, 126 | Contacto en §1 y §17 |
| `docs/legal/PRIVACIDAD.md` | 8, 84, 107 | Responsable, derechos y §14 |
| `lib/features/padre/legal/textos_legales.dart` | 40, 52, 172, 183, 264, 289 | Espejo legal dentro de la app |

`scripts/aws/publicar_legal.sh` se niega a publicar mientras siga ese correo (comprobación documentada en `docs/infra/aws-freemium.md`). El dominio `bluetalk.app` solo se usa en el correo de ejemplo: **no se ha verificado que esté registrado, que sea del dueño ni que tenga buzón**.

### Inventario de cuentas y credenciales

| Pieza | ¿Existe hoy? | Qué falta | Dónde se usa | Custodio |
|---|---|---|---|---|
| Cuenta de desarrollador de Play | **No verificada** | Alta (25 USD), identidad, 2FA y dispositivo de verificación | Play Console | Dueño |
| Play App Signing / clave de subida | **Parcial:** `key.properties` apunta a un keystore que no está | Keystore, alias `bluetalk`, contraseña y huella SHA-256 | Firma del AAB | Dueño |
| Correo de soporte y privacidad | **No:** solo `demo@` | Buzón real, atendido y probado; puede haber alias `soporte@` y `privacidad@` | Legal, ficha y Play | Dueño |
| Dominio y DNS | **No verificado** | Titularidad, renovación, registros MX y HTTPS | URL legal y correo | Dueño |
| Identidad legal | **Solo el alias `LimitCodev`** | Nombre o entidad, NIF, dirección y país; deben coincidir con el perfil de pagos | Legal y Play Console | Dueño |
| Página de ayuda/FAQ | **No** | Decidir si se publica una URL y qué contiene | Ficha y modo padre | Dueño + código |
| Cuenta de AWS (solo si se usa) | **No** | MFA, alarma de gasto, usuario IAM mínimo y plan de pago antes de 6 meses | S3, CloudFront y Polly | Dueño |
| Gestor de credenciales | **No consta** | Guardar accesos y códigos de recuperación; el keystore va aparte, en copia cifrada | Todas | Dueño |

### Acciones nuevas (no estaban contadas en §1–§8)

- [ ] **P0 — Dominio:** verificar quién es el titular de `bluetalk.app`, la fecha de renovación y el DNS; activar MX para el correo y HTTPS para la web legal. Si el dominio no está libre, decidir otro antes de imprimirlo en los textos.
- [ ] **P0 — Buzón real:** crear el correo de soporte/privacidad (por ejemplo `hola@bluetalk.app` con alias `privacidad@`), probar que recibe desde fuera y definir un plazo de respuesta publicable.
- [ ] **P0 — Custodia:** guardar las credenciales de Play, correo, registrador y AWS en un gestor de contraseñas con 2FA y códigos de recuperación; el keystore y su contraseña, en copia cifrada fuera del equipo y fuera del repositorio.
- [ ] **P0 — AWS o alternativa:** si la web legal se publica en AWS, crear la cuenta con MFA, alarma de gasto y usuario IAM mínimo (nunca la cuenta root para el día a día); si se elige otro alojamiento, documentar dónde y quién paga.
- [ ] **P1 — Ayuda/FAQ:** decidir si habrá una página de ayuda pública con preguntas frecuentes y enlazarla en la ficha; no es una cuenta dentro de la app ni sustituye al buzón.

### Criterio de terminado

1. Desde un teléfono sin sesión se abre la URL legal, se leen política y términos, y el correo indicado recibe un mensaje real.
2. Play Console muestra el mismo correo de desarrollador y la misma URL que la ficha y la app.
3. `grep -R "demo@bluetalk.app" docs/legal lib/features/padre/legal` no devuelve nada.
4. El keystore restaurado firma el AAB y su contraseña no está escrita en ningún archivo del repositorio.
5. Una persona distinta del dueño puede entrar al panel de Play con su propio usuario y 2FA, sin compartir la contraseña principal.

### Lo que no se hace desde este equipo

- No se crean cuentas, buzones, dominios ni claves reales.
- No se escriben contraseñas, tokens ni códigos de recuperación en informes, commits o logs.
- No se usa el correo personal del dueño en la ficha si no quiere que sea público.

---

## 4. Declaraciones de Play Console — P0

No se puede publicar sin completar, como mínimo:

- [ ] **Seguridad de los datos**: declarar que no se recogen ni comparten datos; explicar que el almacenamiento es local y que la voz se pasa al sintetizador del sistema.
- [ ] **Público objetivo y Familias**: la app es para menores; declarar los grupos de edad y cumplir la Política de Familias.
- [ ] **Salud**: declarar que no es una app médica y que los check-ins y observaciones son orientativos; añadir el disclaimer en la ficha.
- [ ] **Clasificación de contenido (IARC)**: completar el cuestionario; previsiblemente “Todos”/PEGI 3.
- [ ] **Anuncios**: declarar que no hay anuncios.
- [ ] **Acceso a la app**: explicar que no hay login y que el código de adulto se crea en el primer uso; indicar cómo llegar al panel del adulto para la revisión.
- [ ] **Permisos**: revisar que la edición Play no pide VPN, acceso al uso, administrador de dispositivo ni servicios en primer plano.
- [ ] **Eliminación de cuenta**: no aplica; no hay cuentas.
- [ ] **Publicidad/ID de publicidad**: no aplica.
- [ ] **Funciones financieras, gobierno, noticias, COVID**: no aplica.

---

## 5. Ficha de Play — P0/P1

### Ya listo

- Icono `docs/play/assets/icono-512.png`: 512×512, PNG RGBA opaco, 21 KB.
- Gráfico destacado `docs/play/assets/grafico-destacado-1024x500.png`: 1024×500, RGB, 40 KB.
- Nombre, descripción corta, descripción completa y novedades en `docs/play/ficha.md`.

### Qué falta

- [ ] Sustituir `[URL pendiente]` de la descripción completa por la URL real.
- [ ] Poner un correo de contacto real en la ficha.
- [ ] Regenerar las capturas de teléfono con la interfaz actual. Las de `docs/play/capturas/telefono-2026-11-09/` son de 720×1280 y son válidas técnicamente, pero son anteriores a los cambios de menú del 12 y 16-nov.
- [ ] Añadir capturas de tablet (2–4 recomendadas; no obligatorias).
- [ ] Revisar que ninguna captura muestre nombres, caras, datos reales ni información personal.
- [ ] Confirmar categoría (Educación), etiquetas y “Novedades”.
- [ ] Revisar que los textos no prometan diagnóstico, tratamiento ni curación.

---

## 6. Repositorio y release — P0

### Estado verificado

- Rama actual: `feat/integracion-menu-graficos`.
- `git status --porcelain` mostraba **28 entradas** sin commit antes de crear este informe. Con este informe y el de rendimiento por módulos son **30**; el resto son cambios de código, tests y documentación.
- Hay cambios de rendimiento P0/P1 sin commitear en:
  - `lib/data/local/repo_uso.dart`
  - `lib/features/ajustes/settings_controller.dart`
  - `lib/data/local/repo_contenido_seed.dart`
  - `lib/features/comunicador/tts_service.dart`
  - `lib/features/inicio/inicio_screen.dart`
  - y otros archivos de `lib/`, `test/` y `docs/`.
- `README.md` tiene un diff grande sin commit.
- Hay archivos sin seguimiento como `docs/plan/15-mejores-ajustes-padre.md`, `docs/branding/mascota/`, `lib/core/layout/`, `lib/features/guia/` y `mascota/`.

### Qué falta

- [ ] Decidir qué se commitea y qué se descarta; no hacer `git add -A`.
- [ ] Commitear los arreglos verdes (ya pasan `analyze` y `test`).
- [ ] Pasar `flutter analyze` y `flutter test` desde el árbol limpio.
- [ ] Crear un commit/tag de release reproducible.
- [ ] Verificar que el AAB se construye desde ese commit, no desde el árbol sucio.
- [ ] No incluir en un repo público los audios, fotos y capturas personales de la raíz (`AUDIO-*.mp4`, `WhatsApp Image*.jpeg`, `xdgi.jpeg`, `Ynocencio_foto.jpg`). Añadirlos a `.gitignore` si el repo se va a publicar.
- [ ] Valorar añadir CI para que `analyze` y `test` no dependan de que alguien se acuerde.

---

## 7. Prueba en dispositivo y rendimiento — P1

### Qué falta

- [ ] Instalar el **AAB real** desde prueba interna en un teléfono físico; no basta el APK debug.
- [ ] Probar en Android 7 (mínimo), Android 13 (permiso de avisos) y Android 15/16 (edge-to-edge y predictive back).
- [ ] Probar:
  - voz con y sin motor TTS en español;
  - avisos con permiso concedido y denegado;
  - botón Atrás en comunicador, juegos, rutinas y modo padre;
  - modo calma y tamaño de texto;
  - PIN, recuperación y biometría;
  - instalación/actualización desde Play.
- [ ] Perfilar en un teléfono de gama baja con `flutter run --profile`: arranque, comunicador, juegos y panel de informes.
- [ ] Medir el informe mensual después de los arreglos; el dato de 39,4 ms/fotograma es de emulador con SwiftShader y no representa al dispositivo objetivo.
- [ ] Verificar el AAB ofuscado en dispositivo: R8 y `--obfuscate` pueden romper plugins por reflexión.
- [ ] Confirmar 16 KB en un emulador/dispositivo de 16 KB si está disponible.

### Estado

El rendimiento en gama baja y el comportamiento del AAB ofuscado quedan **NO VERIFICADOS** hasta que se hagan estas pruebas. El detalle por módulos, con lo ya corregido en el árbol y lo que sigue abierto, está en `docs/informes/rendimiento-por-modulos-2026-11-18.md`.

---

## 8. Detalles de release que conviene cerrar — P1

- [ ] `versionName` actual: `0.1.0`. Decidir si la primera publicación será `1.0.0`.
- [ ] `versionCode` actual: `1`. Definir estrategia para que cada subida a Play tenga un código mayor.
- [ ] Archivar el `mapping.txt` de R8 junto a los símbolos Dart; hoy `build-aab.sh` guarda los símbolos Dart pero no el mapping.
- [ ] Valorar `--strip` para reducir el DWARF que el build avisa que queda en las librerías nativas.
- [ ] `dart format` detecta **170 de 323 archivos** que cambiarían. Hacerlo en un commit aparte, no mezclado con la release.
- [ ] 38 paquetes tienen versiones más nuevas. No actualizar antes de publicar sin volver a pasar la suite; los directos relevantes son `flutter_local_notifications 22.3.3`, `flutter_riverpod 3.5.0`, `flutter_svg 2.4.0`, `go_router 18.1.4`.
- [ ] `flutter_tts` aplica Kotlin Gradle Plugin; Flutter avisa de que futuras versiones fallarán. Es deuda de mantenimiento, no un bloqueo actual.
- [ ] Valorar un icono monocromo para Android 13+ (opcional).

---

## 9. Lo que ya está bien (para no repetirlo)

Verificado el 2026-11-18:

- `flutter analyze` → `No issues found!`.
- `flutter test` → `456/456` tests.
- `dart fix --dry-run` → `Nothing to fix!`.
- Sin `print()` en `lib/` y sin `// ignore:`.
- `targetSdk 36`, `minSdk 24`.
- AAB con `arm64-v8a`, `armeabi-v7a` y `x86_64`.
- Librerías nativas alineadas a 16 KB en la compilación de prueba.
- Edición `play` sin INTERNET, VPN, acceso al uso ni administrador de dispositivo; solo permisos normales.
- `debuggable=false` en release; `allowBackup=false`.
- R8, `shrinkResources`, ofuscación, separación de símbolos y tree-shaking de iconos.
- Icono y gráfico destacado listos; textos de ficha redactados.
- Sin anuncios, sin analítica, sin cuentas y con datos locales.
- Crédito de Mulberry y licencia OFL de Nunito incluidos.

---

## 10. Orden recomendado

1. Restaurar el keystore y generar el AAB real.
2. Corregir política, correo, identidad y URL; publicar la política.
3. Limpiar el repositorio, commitear y etiquetar la release.
4. Crear/verificar la cuenta de Play y Play App Signing.
5. Subir a prueba interna y probar el AAB en dispositivo.
6. Completar las declaraciones y la ficha.
7. Iniciar la prueba cerrada de 12 testers/14 días.
8. Solicitar producción y desplegar de forma gradual.

---

## 11. NO VERIFICADO

- El estado real de Play Console: si la cuenta ya existe o no.
- La disponibilidad del nombre `BlueTalk` y del paquete `com.limitcodev.bluetalk` en Play.
- El comportamiento del AAB real en un teléfono físico.
- El rendimiento en gama baja.
- La alineación de 16 KB en un dispositivo con páginas de 16 KB.
- La aprobación de Play a la política, la clasificación y las declaraciones.

---

## Evidencia de esta revisión

Comandos ejecutados el 2026-11-18:

```bash
flutter analyze
flutter test
dart fix --dry-run
dart format --output=none --set-exit-if-changed lib test
flutter pub outdated
./scripts/build-aab.sh          # se detiene por falta de keystore
```

Compilación de prueba: copia temporal con clave desechable, AAB de 55,9 MB, firma JAR correcta y librerías alineadas a 16 KB. La copia y la clave de prueba se borraron. No se modificó el código ni la configuración: los únicos archivos añadidos son este informe y `docs/informes/rendimiento-por-modulos-2026-11-18.md`. No se creó ninguna cuenta ni clave real.
