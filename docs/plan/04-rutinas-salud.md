# Plan 04 — `rutinas-salud` (Ola 2, paralelo, esfuerzo M)

**Depende de:** `base-flutter` (Ola 1 terminada).
**Rutas dueñas:** `lib/features/{rutinas,salud,entorno}/**`, `test/rutinas/**`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

Portar el horario de la web (rutas `/horario`, "Actividades por día") y construir el **enfoque de salud** + la pantalla de **entorno/colegio con datos 100% ficticios**.

## Alcance detallado

1. **Horario / Rutinas** (`rutinas/`, ruta `/home/horario`)
   - Vista niño: lista de "Actividades por día" con hora, picto y estado (hecha/pendiente) — tocar marca como hecha (feedback suave).
   - Vista padre: crear/editar/eliminar actividad (nombre, hora, picto), "Nueva hora" como en la web.
   - Persistencia Drift (`ScheduleRepo`), semilla de ejemplo ya cargada en Ola 1.
   - Recordatorio MVP: **aviso in-app** al abrir (banner "Siguiente actividad: …") + opcional notificación local vía `flutter_local_notifications` si el permiso fue concedido. (Pregunta 5 del plan 00 define alcance final.)

2. **Salud / Bienestar** (`salud/`, ruta `/home/salud`) — enfoque de salud MVP:
   - **Check-in emocional:** el niño elige cómo se siente (pictos de emociones) → `WellbeingRepo` (alimenta dashboard padre).
   - **Hábitos simples:** agua, descanso visual, movimiento — checklist diaria con pictos (semilla configurable).
   - **Modo sensorial:** acceso rápido a Modo calma y ajuste de voz desde aquí (comodidad, no duplicar la lógica).
   - **Disclaimer:** "Esta app no reemplaza evaluación profesional. Consulta a tu especialista." en la cabecera de la sección.

3. **Entorno / Colegio** (`entorno/`, ruta `/home/entorno`)
   - "Mi entorno": pantalla **100% ficticia** — "Colegio Demostración Norte", contacto demo (`demo@bluetalk.app`, "Coordinadora: Sra. Ejemplo"), agenda de "primer contacto al entorno" como guía ilustrada con pictos (rutina de llegada, saludo, despedida).
   - **Prohibido:** nombres reales (Laura, Colegio San Miguel), teléfonos o datos reales. Marcado como "Datos de demostración" en la pantalla.

4. **Estadísticas básicas** (junto al horario): uso por día, check-ins completados (barras nativas, sin recharts).

## Fuera de alcance

Diagnóstico (va en modo padre, plan 05), sincronización con agendas externas, GPS, notificaciones remotas.

## Commits previstos (ejemplos)

```
FEAT: horario del niño con actividades por dia
FEAT: edicion de horario en modo padre con pictos
FEAT: check-in emocional para bienestar del niño
FEAT: checklist de habitos diarios con pictos
FEAT: pantalla de entorno escolar con datos de demostracion
DOCS: disclaimer de salud en la seccion de bienestar
FEAT: aviso in-app de siguiente actividad
TEST: marcar actividad como hecha persiste en drift
```

## Criterios de aceptación

- [ ] Horario completo: ver, marcar, editar (padre), persiste en Drift.
- [ ] Check-in emocional y hábitos registrados y visibles para dashboard padre (plan 05).
- [ ] Pantalla de entorno con **cero datos reales** (grep de nombres reales antes del commit).
- [ ] Disclaimer de salud presente.
- [ ] `flutter analyze` 0 issues; tests en verde.
