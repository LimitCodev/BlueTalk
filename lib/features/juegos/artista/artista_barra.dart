import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'artista_controller.dart';
import 'artista_botones_accion.dart';
import 'artista_acciones.dart';
import 'artista_selectores.dart';

/// Barra de herramientas compacta arriba del lienzo (plan 13 P2):
/// colores, grosor, goma, deshacer, guardar, galería y borrar todo (≥48dp).
class BarraHerramientas extends ConsumerStatefulWidget {
  const BarraHerramientas({super.key});

  @override
  ConsumerState<BarraHerramientas> createState() => _BarraHerramientasState();
}

class _BarraHerramientasState extends ConsumerState<BarraHerramientas> {
  /// Segundo toque pendiente en «Borrar todo»: sin diálogo largo, el
  /// propio botón pide la confirmación (plan 13 P2).
  bool _confirmandoBorrado = false;

  /// Cualquier otra acción de la barra cancela una confirmación pendiente.
  void _cancelarConfirmacion() {
    if (_confirmandoBorrado) setState(() => _confirmandoBorrado = false);
  }

  /// [accion] precedida de [_cancelarConfirmacion].
  VoidCallback _tras(VoidCallback accion) => () {
    _cancelarConfirmacion();
    accion();
  };

  static const _minimo = Size(64, 48);

  Future<void> _guardar() async {
    _cancelarConfirmacion();
    await guardarDibujo(context, ref);
  }

  void _borrarTodo() {
    if (!_confirmandoBorrado) {
      setState(() => _confirmandoBorrado = true);
      return;
    }
    setState(() => _confirmandoBorrado = false);
    ref.read(artistaProvider.notifier).borrarTodo();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(artistaProvider);
    final controller = ref.read(artistaProvider.notifier);
    final vacio = estado.trazos.isEmpty && estado.activo == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilaColores(antes: _cancelarConfirmacion),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilaGrosores(antes: _cancelarConfirmacion),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: _minimo),
                onPressed: _tras(controller.alternarGoma),
                icon: Icon(estado.goma ? Icons.cleaning_services : Icons.brush),
                label: Text(estado.goma ? 'Goma activa' : 'Goma'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: _minimo),
                onPressed: vacio ? null : _tras(controller.deshacer),
                icon: const Icon(Icons.undo),
                label: const Text('Deshacer'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: _minimo),
                onPressed: estado.trazos.isEmpty ? null : _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
              BotonMisDibujos(antes: _cancelarConfirmacion),
              BotonBorrarTodo(
                confirmando: _confirmandoBorrado,
                onPressed: vacio ? null : _borrarTodo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
