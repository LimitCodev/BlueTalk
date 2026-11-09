import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import 'actividad_tile.dart';
import 'rutinas_providers.dart';

/// Tarjetas de la actividad actual y la siguiente, y el botón «Listo».
class PasosPrimeroLuego extends ConsumerStatefulWidget {
  const PasosPrimeroLuego({super.key, required this.primero, this.luego});

  final ScheduleEntry primero;
  final ScheduleEntry? luego;

  @override
  ConsumerState<PasosPrimeroLuego> createState() => _PasosState();
}

class _PasosState extends ConsumerState<PasosPrimeroLuego> {
  /// Un doble toque no debe completar también la actividad siguiente.
  static const _pausaTrasListo = Duration(milliseconds: 700);

  bool _ocupado = false;

  Future<void> _listo() async {
    setState(() => _ocupado = true);
    await marcarActividad(ref, widget.primero, hecha: true);
    await Future<void>.delayed(_pausaTrasListo);
    if (mounted) setState(() => _ocupado = false);
  }

  @override
  Widget build(BuildContext context) {
    final luego = widget.luego;
    // «Listo» fuera de la lista: en un teléfono pequeño siempre se ve.
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            children: [
              _Tarjeta(rotulo: 'Primero', entry: widget.primero),
              const SizedBox(height: 8),
              if (luego != null)
                _Tarjeta(rotulo: 'Luego', entry: luego)
              else
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Es la última actividad de hoy.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(64),
            ),
            onPressed: _ocupado ? null : _listo,
            child: const Text('Listo'),
          ),
        ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.rotulo, required this.entry});

  final String rotulo;
  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(rotulo, style: t.titleMedium),
            const SizedBox(height: 8),
            PictoMini(entry.pictoId, size: 88, semanticsLabel: entry.title),
            const SizedBox(height: 8),
            Text(entry.title, textAlign: TextAlign.center, style: t.titleLarge),
            Text(formatHora(entry.timeMinutes), style: t.bodyMedium),
          ],
        ),
      ),
    );
  }
}
