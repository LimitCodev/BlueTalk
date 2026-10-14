import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';
import 'actividad_tile.dart';
import 'rutinas_controller.dart';
import 'rutinas_providers.dart';

/// Vista de persona adulta: crear, editar y eliminar actividades del
/// horario (plan 04 §1, "Nueva hora" como en la web).
///
/// El gate con PIN del modo padre pertenece a `features/padre` (plan 05);
/// esta vista queda lista para que el coordinador la abra tras el gate.
class EditorHorarioView extends ConsumerWidget {
  const EditorHorarioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horario = ref.watch(horarioProvider);
    final quitadas = ref.watch(quitadasProvider).value ?? const <String, String>{};

    return switch (horario) {
      AsyncData(:final value) => Column(
          children: [
            const _CabeceraEditor(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva hora'),
                  onPressed: () => mostrarEditorActividad(context),
                ),
              ),
            ),
            Expanded(
              child: value.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Todavía no hay actividades. Pulsa "Nueva hora" '
                          'para agregar la primera.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        for (final entry in value)
                          _FilaEditable(entry: entry),
                        if (quitadas.isNotEmpty)
                          _SeccionQuitadas(quitadas: quitadas),
                      ],
                    ),
            ),
          ],
        ),
      AsyncError() => const Center(
          child: Text('No se pudo cargar el horario.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _CabeceraEditor extends ConsumerWidget {
  const _CabeceraEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(rutinasProvider.notifier).irAlInicio(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editar horario',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de actividad con acciones de editar y quitar (≥48dp).
class _FilaEditable extends ConsumerWidget {
  const _FilaEditable({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: PictoMini(entry.pictoId),
        title: Text(entry.title),
        subtitle: Text('A las ${formatHora(entry.timeMinutes)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar ${entry.title}',
              onPressed: () => mostrarEditorActividad(context, entry: entry),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Quitar ${entry.title}',
              onPressed: () => quitarActividad(ref, entry),
            ),
          ],
        ),
      ),
    );
  }
}

/// Actividades quitadas, con opción de restaurar (el "borrado" del contrato
/// actual es deshabilitar; ver informe).
class _SeccionQuitadas extends ConsumerWidget {
  const _SeccionQuitadas({required this.quitadas});

  /// id → nombre de cada actividad quitada.
  final Map<String, String> quitadas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Actividades quitadas',
            style: t.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final MapEntry(:key, :value) in quitadas.entries)
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: Text(value),
            trailing: OutlinedButton(
              onPressed: () => restaurarActividad(ref, key),
              child: const Text('Restaurar'),
            ),
          ),
      ],
    );
  }
}

/// Abre el formulario de actividad (nueva si [entry] es null).
Future<void> mostrarEditorActividad(
  BuildContext context, {
  ScheduleEntry? entry,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: _FormularioActividad(entry: entry),
    ),
  );
}

/// Formulario: nombre, hora y pictograma; guardar persiste vía repo.
class _FormularioActividad extends ConsumerStatefulWidget {
  const _FormularioActividad({this.entry});

  final ScheduleEntry? entry;

  @override
  ConsumerState<_FormularioActividad> createState() =>
      _FormularioActividadState();
}

class _FormularioActividadState extends ConsumerState<_FormularioActividad> {
  late final TextEditingController _nombre;
  late int _minutos;
  String? _pictoId;
  String? _errorNombre;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _nombre = TextEditingController(text: entry?.title ?? '');
    _minutos = entry?.timeMinutes ?? 8 * 60;
    _pictoId = entry?.pictoId;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pictos = ref.watch(pictosPorIdProvider).value?.values.toList() ??
        const <Pictogram>[];
    pictos.sort((a, b) => a.label.compareTo(b.label));

    return Padding(
      padding: const.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.entry == null ? 'Nueva hora' : 'Editar actividad',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombre,
            decoration: InputDecoration(
              labelText: 'Nombre de la actividad',
              hintText: 'P. ej. Recreo',
              errorText: _errorNombre,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Hora: ${formatHora(_minutos)}'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                icon: const Icon(Icons.schedule),
                label: const Text('Cambiar'),
                onPressed: _elegirHora,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _pictoId,
            decoration: const InputDecoration(
              labelText: 'Pictograma (opcional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Sin pictograma'),
              ),
              for (final picto in pictos)
                DropdownMenuItem<String?>(
                  value: picto.id,
                  child: Text(picto.label),
                ),
            ],
            onChanged: (value) => setState(() => _pictoId = value),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _guardar,
                child: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutos ~/ 60, minute: _minutos % 60),
    );
    if (hora == null || !mounted) return;
    setState(() => _minutos = hora.hour * 60 + hora.minute);
  }

  Future<void> _guardar() async {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _errorNombre = 'Escribe el nombre de la actividad');
      return;
    }

    final actual = widget.entry;
    final entry = ScheduleEntry(
      // La edición conserva el id; la actividad nueva genera uno estable.
      id: actual?.id ?? nuevaIdActividad(),
      title: nombre,
      timeMinutes: _minutos,
      pictoId: _pictoId,
      enabled: actual?.enabled ?? true,
    );
    await guardarActividad(ref, entry);
    if (mounted) Navigator.of(context).pop();
  }
}

/// Ids y nombres de las actividades quitadas (deshabilitadas) del horario.
final quitadasProvider = FutureProvider<Map<String, String>>((ref) async {
  final entries = await ref.watch(scheduleRepoProvider).schedule();
  return {
    for (final e in entries)
      if (!e.enabled) e.id: e.title,
  };
});

/// Devuelve al horario una actividad quitada (por id).
Future<void> restaurarActividad(WidgetRef ref, String id) async {
  final entries = await ref.read(scheduleRepoProvider).schedule();
  for (final entry in entries) {
    if (entry.id == id && !entry.enabled) {
      await guardarActividad(
        ref,
        ScheduleEntry(
          id: entry.id,
          title: entry.title,
          timeMinutes: entry.timeMinutes,
          pictoId: entry.pictoId,
          enabled: true,
        ),
      );
    }
  }
}
