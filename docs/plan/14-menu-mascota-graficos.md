# Plan 14 — Menú principal, guía con la mascota y gráficos del adulto

**Para:** el agente que ejecuta. **Léelo entero antes de tocar código**, junto con
`AGENTS.md` y el §0 de `docs/plan/11-fases-1-a-3-excelencia.md`.
**Origen:** pedido del dueño del 2026-11-12, tras probar el APK `dist/BlueTalk-prueba.apk`.

Este plan tiene tres subplanes. Cada uno es un archivo propio:

| Subplan | Archivo | Qué entrega | Depende de |
|---|---|---|---|
| **14A** | `14a-menu-principal.md` | Menú principal animado después del nombre, como `/menu` de la web; cambiar el nombre desde el Modo padre | — |
| **14B** | `14b-guia-mascota.md` | Recorrido guiado la primera vez, con el ave de BlueTalk, fondo gris y hueco iluminado; termina en el Modo padre | 14A (la guía señala las tarjetas del menú) |
| **14C** | `14c-graficos-padre.md` | Gráficos variados en el Modo padre: dona, anillo de porcentaje, línea, calendario, barras apiladas, tarjetas con comparación | — (puede ir en paralelo) |

**Orden recomendado:** 14A → 14B → 14C. 14C no toca el flujo del niño y puede
hacerse antes si el dueño quiere ver gráficos primero.

---

## 1. Flujo completo de la app tras este plan

```
Primer arranque
 └─ /onboarding  «¿Cómo te llamas?» → Comenzar / Entrar sin apodo
     └─ /inicio  Menú principal («¡Hola, Ana! 👋  ¿Qué quieres hacer hoy?»)
         └─ (guía no vista) Guía de la mascota, 11 pasos, encima del menú
             ├─ pasos 1–6: menú y sus tarjetas
             ├─ pasos 7–10: dentro de Comunicar (frase, tablero, categorías, barra superior)
             └─ paso 11: tarjeta «Modo padre» → botón «Ir al Modo padre»
                 └─ /padre  Condiciones → crear código de 6 dígitos → Resumen con gráficos
                     └─ «Salir del modo padre» → /inicio

Arranques siguientes
 └─ /inicio  Menú principal (sin guía)

Desde el menú (orden fijo, nunca se reordena)
 1 Comunicar  → /home/comunicar
 2 Aprender   → /home/aprender
 3 Rutinas    → /home/rutinas
 4 Ajustes    → /home/ajustes
 5 Modo padre → /padre (siempre pide el código)
```

## 2. Tabla del botón Atrás (sustituye a la del plan 13 P1)

| Dónde está | Atrás hace | Cambia respecto a hoy |
|---|---|---|
| Dentro de un juego, cuento, categoría, vista de Rutinas o Mis mensajes | Vuelve a la lista de su sección | No |
| En la lista principal de Aprender, Rutinas o Ajustes | Vuelve al **menú** (`/inicio`) | **Sí** (antes iba a Comunicar) |
| En el inicio de Comunicar | Vuelve al **menú** (`/inicio`) | **Sí** (antes salía de la app) |
| En el **menú** | Sale de la app, salvo con `saleConAtrasProvider == false` (kiosko) | Nuevo; el gancho del kiosko se mueve aquí |
| En el Modo padre (pestaña distinta de Resumen) | Vuelve a Resumen | No |
| En el Modo padre (Resumen o gate) | Sale al **menú** (`/inicio`) | **Sí** (antes iba a Ajustes) |
| Durante la guía | Paso anterior; en el paso 1 no hace nada | Nuevo |

## 3. Reglas que aplican a los tres subplanes

- **Modo calma y «Quitar animaciones» de Android** (`MediaQuery.disableAnimationsOf`)
  apagan **toda** animación nueva: duración cero, sin escala ni pulso. Se prueba con un test por pantalla.
- **Sin dependencias nuevas.** El carrusel usa `PageView`; la guía, `Overlay` + `CustomPainter`;
  los gráficos, `CustomPainter` (regla del plan 13 P5). Si alguna parte lo pide,
  se anota en `docs/informes/decisiones-pendientes.md` y **no** se instala.
- **Ninguna voz automática.** La guía y el menú solo muestran texto.
- Objetivos táctiles de 48 dp o más, contraste AA y `Semantics` en todo lo nuevo.
- **Trinquete de 100 líneas** (`test/arquitectura/tamano_test.dart`): cada archivo nuevo
  tiene 100 líneas o menos. Los que ya están en `_deuda` solo pueden encoger.
- Capas: el almacenamiento va por `almacenLocalProvider`; nada importa `shared_preferences`.
- Por cada paso: `flutter analyze` con 0 problemas, `flutter test` en verde, un commit
  `TIPO: descripción` (70 caracteres o menos, sin `Co-Authored-By`), y una línea en `estado-vivo.log`.
- Evidencia por subplan: `docs/informes/14a-evidencia.md`, `14b-…`, `14c-…`, con capturas del
  emulador en `docs/informes/capturas/14*.png`. Lo que solo se ve en un teléfono es **NO VERIFICADO**.

## 4. Decisiones del dueño (respuestas por defecto si no contesta)

| # | Pregunta | Por defecto |
|---|---|---|
| D1 | ¿Se mantiene la barra inferior (Comunicar · Aprender · Rutinas · Ajustes) dentro de las secciones? | **Sí.** Da acceso rápido a Comunicar y la navegación sigue siendo fija. El menú se abre con un botón «Inicio» (casa) en la barra superior. |
| D2 | ¿La mascota tiene nombre? | Sin nombre. Se presenta como «el ave de BlueTalk». No se inventa un nombre. |
| D3 | ¿La guía tiene botón «Saltar»? | **Sí**, discreto, arriba a la derecha. Al saltar se va directo al Modo padre para crear el código. |
| D4 | ¿Posturas nuevas de la mascota? | **Resuelta (2026-11-12):** hay 11 posturas y ninguna se voltea (14B §2). Pendiente menor: el candado dice «SECURE», en inglés. |
| D5 | Tarjeta «Anuncios» de la web | No entra. La app no tiene red. |
| D6 | Orden «nombre del niño antes que el adulto» frente al plan 12 F1 («adulto primero») | Manda el orden de este plan, que es lo que pidió el dueño. La guía cumple el papel de «configuración del adulto» y termina creando el código. |

## 5. Comprobación de coherencia (hacerla al cerrar cada subplan)

1. Una instalación limpia pasa: nombre → menú → guía completa → condiciones → crear código → Resumen. No hay pantallas muertas ni diálogos encima de la guía.
2. Al matar la app a mitad de la guía, al reabrirla vuelve al menú y la guía empieza en el paso 1.
3. En el segundo arranque se abre el menú sin guía.
4. «Ver la guía otra vez» (Ajustes) la repite. Si el código ya existe, el último paso dice «Aquí entras con tu código».
5. Atrás sigue la tabla del §2 en cada pantalla (test de router y tests de widget).
6. Con el modo calma activo no se mueve nada, y menú, guía y gráficos siguen funcionando.
7. Con TalkBack (`accessibleNavigation`) el menú se muestra como lista y la guía se lee paso a paso.
8. Al girar el teléfono, el hueco de la guía sigue encima del elemento correcto.

## 6. Reparto entre agentes (decisión del dueño, 2026-11-12)

| Agente | Trabajo | Rama | Por qué |
|---|---|---|---|
| **Claude Code** | **14A completo** (incluido A4, el nombre) y **14B completo** | `feat/menu-guia` | Toca el router, el botón Atrás, el shell y anclas repartidas en varias pantallas. Si se deja a medias, rompe el arranque o la navegación. |
| **OpenCode** | **14C completo** | `feat/graficos-padre` | Carpeta propia (`lib/features/padre/graficos/`), funciones puras con tests y commits independientes. Si se corta a mitad, lo ya hecho sigue compilando y nada se rompe. |

Reglas del reparto:

1. Las dos ramas salen del commit que añade este plan. Ningún agente toca archivos del otro subplan.
2. El único archivo compartido es `test/arquitectura/tamano_test.dart` (`_deuda`). Cada agente solo edita
   las líneas de sus propios archivos. Si hay conflicto al unir, se conserva el número más bajo.
3. **OpenCode, una sesión por paso de 14C §5.** Al empezar cada sesión: `git log --oneline -5` y
   `estado-vivo.log` para saber dónde quedó. No empieces un paso nuevo sin cerrar el anterior con su commit.
   Los pasos 5 y 6 (reorganizar Resumen e Informes) van al final, cuando los gráficos ya existen y tienen tests.
4. Cada agente hace `git push` solo de **su** rama. Nada de merge ni push a `main`: el merge lo decide el dueño.
