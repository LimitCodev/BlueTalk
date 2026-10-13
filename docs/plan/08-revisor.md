# Plan 08 — `revisor` (continuo, solo lectura + informes, esfuerzo S por entrega)

**Depende de:** cada entrega de cada agente.
**Rutas dueñas:** `docs/informes/**` (el resto es solo lectura).
**Lee:** `docs/plan/00-PLAN-MAESTRO.md` (sus reglas son el estándar de revisión).

## Misión

Revisar **1x1** cada entrega antes de que el usuario la vea: encontrar problemas reales con referencia `archivo:línea`, en orden de severidad. No escribe código de features; corrige solo si el agente dueño no puede (y aun así, informa).

## Checklist de revisión (aplicar completo a cada entrega)

1. **Seguridad y datos**
   - ¿Hay nombres/datos reales? (Laura, San Miguel, teléfonos, emails reales) → BLOCKER.
   - ¿PIN/hash persistido en claro? ¿Claves en el repo? → BLOCKER.
   - ¿Datos demo etiquetados donde se muestran? ¿Disclaimer de diagnóstico/salud presente? → BLOCKER si falta.

2. **Reglas del plan 00**
   - `pubspec.yaml` tocado fuera de Ola 1 → BLOCKER.
   - `git push` hecho por un agente → BLOCKER.
   - Commit fuera de convención (formato sección 6, texto de IA) → MAJOR (pedir rehacer el mensaje).
   - Carpetas ajenas a las dueñas modificadas → BLOCKER.

3. **Calidad de código**
   - `flutter analyze` 0 issues, `flutter test` verde (ejecutarlos, no confiar).
   - Trabajo pesado en `build()`, listas sin lazy, imágenes sin `cacheWidth`, `print()` en código → MAJOR.
   - Widgets no reutilizando los componentes base → MINOR.

4. **Accesibilidad/autismo**
   - Targets <48dp, contrastes fuera de AA, lenguaje metafórico, autoplay de audio, navegación que rompe el shell → MAJOR.

5. **Rendimiento gama baja**
   - Animaciones caras sin respetar Modo calma, dependencias pesadas nuevas → MAJOR.

## Formato del informe (`docs/informes/NN-<agente>-<fecha>.md`)

```markdown
# Informe — <agente> — <fecha>

Veredicto: APROBADO / CORRECCIONES / BLOQUEADO

## BLOCKER
- [archivo:línea] descripción concreta → acción requerida

## MAJOR
- ...

## MINOR
- ...
```

Máximo ~10 hallazgos por informe (los más importantes); concreto, sin relleno.

## Commits previstos

```
DOCS: informe de revision base-flutter
DOCS: informe de revision aac-comunicador
DOCS: checklist de revision actualizado
```

## Criterios de aceptación del rol

- [ ] Cada entrega de Ola 1–3 tiene su informe antes de pasar a la siguiente.
- [ ] Todo BLOCKER resuelto (commits `FIX:` del agente dueño) y re-verificado.
- [ ] Veredicto final por ola registrado en `docs/informes/`.
