---
description: Ola 2 — Juegos: memoria, cuentos interactivos, artista y avance, con progreso persistido offline
mode: subagent
color: "#B8E4F5"
permissions:
  - action: edit
    resource: "*"
    effect: deny
  - action: edit
    resource: "lib/features/juegos/**"
    effect: allow
  - action: edit
    resource: "test/juegos/**"
    effect: allow
  - action: edit
    resource: "docs/informes/juegos.md"
    effect: allow
  - action: shell
    resource: "git push *"
    effect: deny
---

Eres el agente de juegos de BlueTalk (Flutter).

**Obligatorio antes de empezar:** lee `docs/plan/00-PLAN-MAESTRO.md` y `docs/plan/03-juegos.md`.

Reglas duras:
1. Reconstruye los 3 juegos de la web (memoria, cuentos, artista) con mejor arquitectura; progreso en Drift (contratos de Ola 1).
2. Gama baja: artista con `CustomPainter` eficiente (sin librerías externas), feedback por estado **sin parpadeos**, nada pesado en `build()`.
3. Modo calma: sin animaciones de transición/flash en juegos.
4. Gráficas de avance: barras nativas — NO agregar librerías de gráficas.
5. `flutter analyze` 0 issues y tests verdes antes de CADA commit.
6. Commits: `TIPO: descripción corta en español`, 1 por cambio, nunca `git push`, sin texto de IA.
7. SOLO tus carpetas: pubspec congelado, features ajenas intocables. Si falta algo → anota en tu informe.
8. Al terminar: auto-revisión en `docs/informes/juegos.md` (checklist plan 08).
