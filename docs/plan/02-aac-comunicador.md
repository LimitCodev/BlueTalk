# Plan 02 — `aac-comunicador` (Ola 2, paralelo, esfuerzo L)

**Depende de:** `base-flutter` (Ola 1 terminada).
**Rutas dueñas:** `lib/features/comunicador/**`, `assets/pictos/**`, `test/comunicador/**`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

El corazón de BlueTalk: el comunicador AAC con pictogramas, barra de frase y voz. Funciona **100% offline** y corre fluido en gama baja.

## Alcance detallado

1. **Set de pictogramas** (`assets/pictos/`)
   - **Set principal: Mulberry Symbols** (CC BY-SA 4.0 — comercial permitido, SVG, diseñado para AAC). Complemento puntual con **Twemoji** (CC BY 4.0). **Prohibido ARASAAC** (no-comercial, riesgo legal en Play).
   - Empezar con una **muestra** (~40 pictos de las categorías base: emociones, comida, animales, acciones) para validar el look antes de cargar el set completo. Reutilizar los SVGs ya extraídos en `assets/pictos/muestra/`.
   - SVGs optimizados ≤128 KB, nombres prefijados por categoría, render con `flutter_svg`.
   - Pantalla de créditos obligatoria: "Mulberry Symbols by Steve Lee, CC BY-SA 4.0".
   - Crear `PictogramRepo` impl sobre seeds + assets (ya existe la interfaz en Ola 1).

2. **Pantalla de categorías** (`/home/categorias`)
   - Grid de categorías (Emociones, Acciones, Comida, Animales, Familia, Lugar — misma estructura que la web: 25+ pictos detectados en el bundle).
   - Targets ≥48dp, textos literales, sin animaciones si Modo calma está activo.

3. **Pantalla de categoría** (`/home/categorias/:id`)
   - Grid de pictogramas con imagen + palabra.
   - **Al tocar:** agrega a la barra de frase + habla (flag `speakOnTap`, default ON, silenciable con icono de altavoz en la barra).

4. **Barra de frase**
   - Pictos agregados con X para quitar, "Borrar todo", botón **Leer** (TTS de la frase completa), opción "Guardar en mis mensajes".

5. **TTS** (`lib/features/comunicador/tts_service.dart`)
   - `flutter_tts`, idioma `es-ES`/`es-MX` con fallback + aviso claro si la voz no está instalada (plan 00 §11).
   - Rate/pitch controlables desde Ajustes (contrato ya creado).
   - **Sin autoplay:** solo habla bajo taps.

6. **Integración con datos**
   - Cada picto tocado → `UsageRepo.log(UsageEvent)` (alimenta el dashboard del modo padre, plan 05).
   - Mensajes guardados → tabla local (Drift).

7. **Búsqueda y favoritos**
   - Buscador simple por palabra (case-insensitive).
   - Favoritos: mantener presionado un picto → fijar a la pantalla de inicio del comunicador.

8. **Estados:** vacío ("Toca los pictogramas para crear un mensaje..."), error de assets, carga.

## Fuera de alcance

Juegos, estadísticas (gráficas), TTS del modo padre, edición de categorías (futuro), sync.

## Commits previstos (ejemplos)

```
CHORE: set de pictogramas openmoji optimizado y con creditos
FEAT: pantalla de categorias con grid accesible
FEAT: comunicador con barra de frase y leccion de mensaje
FEAT: voz tts en español con aviso si falta la voz
FIX: tts no hablaba tras perder el foco en gama baja
FEAT: buscador de pictogramas y favoritos a inicio
TEST: flujo agregar picto genera usageevent
```

## Criterios de aceptación

- [ ] Flujo completo offline: categoría → picto → frase → leer.
- [ ] Voz en español funciona (o aviso claro si falta la voz del sistema).
- [ ] Uso por categoría se registra y es visible para el dashboard de padre.
- [ ] `flutter analyze` 0 issues; tests del flujo en verde.
- [ ] Sin `build()` pesado: grid lazy (`GridView.builder`), imágenes cacheadas.
- [ ] Los pictos cumplen licencia abierta + pantalla de créditos enlazada desde Ajustes.
