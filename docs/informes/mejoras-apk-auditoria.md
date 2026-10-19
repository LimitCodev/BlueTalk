# Mejoras de APK por auditoría (2026-10-18)

Pulido corto entre Etapa B y Etapa C, pedido por el dueño: revisar los
`.md` de auditoría y mejorar el APK con lo que marque «pendiente».
Regla de este informe: verificado = ejecutado y visto; lo no verificado
se declara como **NO VERIFICADO**.

## Auditorías leídas (y su estado)

| Auditoría | Qué decía | Estado |
|---|---|---|
| `etapa-a-revisor.md` (2026-10-16) | 0 GRAVE, 3 MEDIO, 6 LEVE | **Cerrada**: MEDIO-1/2 corregidos (`5ac4d4e`, `4f355b2`), MEDIO-3 anotado sin reescribir historia, LEVE 4–9 corregidos en el cierre |
| `etapa-b-revisor.md` (2026-10-18) | 0 GRAVE, 2 MEDIO, 6 LEVE | **Cerrada**: MEDIO corregidos (`0979d1d`, `de7e47a`), LEVE corregidos (`961193d`, `b18e4af`, `4e198df`) |
| `reports/apps-aac-autismo-mejoras-bluetalk.md` (quick wins Ola 2) | 8 mejoras de coste bajo | Ya hechas: 1 (diagnóstico de voz, Etapa A), 3 (velocidad de voz en Control/Salud). **Hechas ahora: 2, 7, 8.** Pendientes: 4 (→ Etapa C), 5 (→ Etapa C), 6 (correo del dueño) |
| `decisiones-pendientes.md` | keystore, applicationId, correo git | Keystore ya resuelto (2026-10-15); resto sigue esperando al dueño |

## Cambios de esta tanda (3 commits, gates antes de cada uno)

| Quick win | Qué se hizo | Commit | Verificación |
|---|---|---|---|
| 2 — regresión táctil | Tests que fijan: repetir el mismo picto 3 veces entra 3 veces (podría decir «no, no, NO»); arrastrar el dedo sobre los pictos **no** los activa | `b0e4a68` TEST | `flutter test` 250/250. **Honesto: el comportamiento ya era correcto** (InkWell no dispara en arrastre); lo que faltaba era el test que lo impide romper |
| 7 — modelado | Línea literal en la bienvenida: «Consejo para enseñar: señala y di la palabra mientras el niño toca el pictograma» | `e334723` FEAT | 251/251 + test nuevo del texto + gate de accesibilidad. **Lección:** la primera posición (antes de los botones) rompió el test P6.1 («Comenzar visible con el teclado abierto»); el consejo quedó **debajo** de los botones |
| 8 — disclaimer | «Esta app no realiza evaluaciones ni pruebas de detección («screening»): no clasifica a las personas ni indica si tienen alguna condición» en Términos §8, en el `.md` maestro **y** en el espejo de la app | `00ee6bc` FEAT | 252/252; test que exige la frase en ambos lados del espejo |

Gates de la tanda completa: `flutter analyze` **0 problemas**,
`flutter test` **252/252**.

## APK de reparto

- Reconstruido con `scripts/build-apk.sh` tras los 3 commits (el de
  `dist/` era del 16 oct, anterior a la Etapa B: logo, ícono, paletas y
  nombre «BlueTalk»).
- Firma: keystore propio (`~/keystores/bluetalk-release.keystore`,
  fuera del repo; decisiones-pendientes.md §keystore).
- Resultado verificado (salida del script, 2026-10-18):
  - `dist/BlueTalk.apk` (arm64-v8a, el de reparto): **20,3 MB**,
    SHA-256 `e96878ae94d4bfb827fe78311f66f1b6abc2392b9cded544540b75fb886fd779`
  - `armeabi-v7a` 17,8 MB · `x86_64` 21,7 MB (uno por arquitectura).
- Firma verificada con `apksigner --print-certs`:
  `CN=BlueTalk, O=BlueTalk` (el keystore propio, no la clave de
  depuración de plantilla).
- El hash se publica junto al enlace, tal como manda
  `docs/play/instalar-apk.md`.

## NO VERIFICADO (requiere teléfono físico)

- Instalar el APK nuevo en el móvil del dueño (los avisos de Play
  Protect y el comportamiento táctil real).
- El consejo de modelado y el disclaimer vistos en pantalla real.
- Fotograma de arranque, PNGs heredados del ícono (API < 26) y medidas
  en API 24: siguen de la Etapa A/B.

## Pendiente conocido (no se tocó aquí)

- **Etapa C (plan 11 Fase 2):** vocabulario 200+, 30–50 pictos núcleo
  (quick win 4), posiciones fijas del vocabulario nuclear (quick win 5),
  Primero–Luego, fotos propias, copia de seguridad.
- **Quick win 6 — FAQ y contacto:** necesita el correo real del dueño →
  anotado en `decisiones-pendientes.md`.
- Quick wins 9–17 (roadmap Ola 3+): exportación, informes OBF/.obl,
  predicción, etc.
