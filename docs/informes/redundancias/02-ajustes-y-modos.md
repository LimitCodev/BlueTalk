# Redundancias — ajustes y modos

El mismo estado se puede cambiar desde varios sitios. No siempre es un error
(atajos deliberados), pero cuando dos controles aparecen **en la misma
pantalla** o con etiquetas distintas, sobra uno.

## R-04 · El modo calma se controla desde cinco sitios (P1, decisión de producto)

**Dónde**
| # | Control | Archivo |
|---|---|---|
| 1 | Icono de contraste en el AppBar del menú | `inicio_screen.dart:73` |
| 2 | Icono de contraste en el AppBar del shell | `shell.dart:78` |
| 3 | `CalmModeToggle` (interruptor con subtítulo) en Ajustes | `ajustes_screen.dart:25` |
| 4 | `CalmModeToggle` en “Mi día” (Modo sensorial) | `salud_screen.dart:44` |
| 5 | `CalmModeToggle` en Control del padre (“Pantalla y voz”) | `control_rutina_voz.dart:33` |

Los cinco escriben `calmModeProvider` y persisten la misma clave.

**Qué se ve a la vez**
- En Ajustes: el icono del shell + el interruptor (dos controles).
- En “Mi día”: el icono del shell + el interruptor (dos controles).
- En Control del padre: el interruptor; el padre tiene su propio AppBar, así
  que no hay icono del shell.

**Por qué importa**
No es solo un botón de más: el mismo ajuste tiene dos presentaciones (icono
sin texto y switch con subtítulo) y tres sitios donde buscarlo. Un adulto
puede apagar el modo calma en “Mi día” creyendo que solo afecta a esa
pantalla; en realidad afecta a toda la app.

**Recomendación (mínima)**
- Dejar el icono del menú/shell como atajo global (es el acceso rápido que
  pide el plan 00 §4).
- Dejar **un** interruptor descriptivo en Ajustes.
- En “Mi día” y en Control, sustituir el interruptor por un `ListTile` que
  enlace a Ajustes, igual que ya hace Control con “Tamaño de texto y
  velocidad de voz”. Así el control principal es único y el atajo no engaña.

Si el dueño prefiere que “Modo sensorial” siga teniendo su interruptor por
contexto (es una pantalla de bienestar), entonces quitar el de Ajustes o el
icono del shell, pero no dejar dos en la misma pantalla. **Es una decisión de
producto**: anotar la elegida antes de tocar.

**Riesgo** bajo. Test: abrir Ajustes y “Mi día” y comprobar que el control de
calma aparece una sola vez por pantalla.

---

## R-05 · La velocidad de la voz tiene dos sliders distintos (P1, S)

**Dónde**
- `lib/features/ajustes/ajustes_voz.dart` — `TtsSection`: “Velocidad de la
  voz” (0,2–0,9) y “Tono de la voz” (0,6–1,4), con nota “La voz suena solo
  cuando tocas…”.
- `lib/features/salud/salud_screen.dart:244` — `_VozRapida`: “Velocidad de la
  voz” (0,2–0,9), con etiqueta “Velocidad 0.5”.

Ambos escriben `settings.ttsRate`; el de Salud no tiene tono.

**Por qué importa**
Dos sliders para el mismo valor, con textos y formato distintos. Si el adulto
cambia uno, el otro se mueve al volver; puede parecer un fallo. Además, Salud
es la pantalla del niño, no el sitio natural para un ajuste técnico de voz.

**Fix pequeño**
Quitar `_VozRapida` de “Mi día” y dejar un `ListTile`:
“La velocidad y el tono de la voz se cambian en Ajustes” → `go('/home/ajustes')`.
Es exactamente el patrón que ya usa `SeccionesRutinaYVoz` en Control.

**Riesgo** bajo. Actualizar el test de `salud_screen` si comprueba el slider.

---

## R-21 · Control dice “esto se cambia en Ajustes” justo al lado de un ajuste duplicado (P1, incluido en R-04)

**Dónde** `control_rutina_voz.dart:33-47`.

El mismo bloque tiene:
- `CalmModeToggle` (control real, duplicado de Ajustes);
- `ListTile` “Tamaño de texto y velocidad de voz” con subtítulo “Se cambian
  en la pestaña Ajustes” (enlace, sin duplicar).

La intención del código es clara: no duplicar lógica en Control. El calma se
quedó fuera de esa regla. Al resolver R-04, aplicar la misma pauta: enlace,
no control.

---

## R-06 · Tres entradas al modo padre (verificado, no tocar)

1. Tarjeta “Modo padre” del menú (`menu_opciones.dart`).
2. “Modo padre” en Ajustes > Zona de adultos (`ajustes_info.dart:25`).
3. Final de la guía de la mascota (`guia_capa.dart:_terminar`).

Son contextos distintos: el menú es la entrada principal, Ajustes es el atajo
discreto para el adulto que ya está configurando, y la guía lleva una sola vez
al crear el código. No se pisan en la misma pantalla. Se conservan.

Lo único a vigilar: las tres deben pedir el PIN (lo hace el gate) y ninguna
debe saltárselo. Hoy es así.

---

## R-07 · “Uso del teléfono” con dos entradas (verificado, no tocar)

- Tarjeta `UsoTelefonoResumen` en el Resumen del padre (solo edición directa).
- `ListTile` “Tiempo por app” en Control > Diagnóstico de uso.

Ambas abren `UsoTelefonoScreen` y leen los mismos providers. La primera es un
resumen de un vistazo; la segunda está junto a los permisos y el filtro. No
duplican lógica. Se conservan.

Cuidado si se cambia el texto de una: el estado “sin permiso” debe seguir
siendo literal y coherente en las dos.

---

## R-15 · “Tu avatar” solo en Ajustes (verificado)

El onboarding no elige avatar; solo pide el apodo (`onboarding_screen.dart`).
`AvatarSection` es la única entrada y usa `AvatarOption`. No hay copia en
otra pantalla.

---

## R-16 · Interruptor de recordatorios y permisos (verificado)

`RecordatoriosSection` es el único sitio que enciende/apaga los avisos; el
permiso se pide desde ahí y desde el asistente de permisos, pero el asistente
solo muestra el estado y lanza el diálogo de Android, no cambia
`remindersEnabled`. No hay dos fuentes de verdad.

---

## Resumen de acciones

| Acción | Archivos | Decisión |
|---|---|---|
| Dejar un solo interruptor de calma + enlaces en Salud/Control | `salud_screen.dart`, `control_rutina_voz.dart`, `ajustes_screen.dart` | producto: elegir dónde queda el interruptor |
| Quitar `_VozRapida` y enlazar a Ajustes | `salud_screen.dart` | recomendado |
| No tocar las tres entradas al padre ni las dos de uso | — | verificado |
