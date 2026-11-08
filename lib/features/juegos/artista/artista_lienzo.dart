import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import 'artista_canvas.dart';
import 'artista_controller.dart';

/// El lienzo: dos capas apiladas (trazos terminados + trazo activo) para
/// que arrastrar solo repinta un path (plan 03 §4).
class Lienzo extends ConsumerStatefulWidget {
  const Lienzo({super.key});

  @override
  ConsumerState<Lienzo> createState() => _LienzoState();
}

class _LienzoState extends ConsumerState<Lienzo> {
  Size _tamano = Size.zero;

  /// Puntero que está dibujando: el resto (palma, segundo dedo) se ignora.
  int? _punteroActivo;

  void _empezar(PointerDownEvent evento) {
    if (_punteroActivo != null) return;
    _punteroActivo = evento.pointer;
    ref
        .read(artistaProvider.notifier)
        .empezarTrazo(evento.localPosition, _tamano);
  }

  void _mover(PointerMoveEvent evento) {
    if (evento.pointer != _punteroActivo) return;
    ref
        .read(artistaProvider.notifier)
        .continuarTrazo(evento.localPosition, _tamano);
  }

  void _terminar(int puntero) {
    if (puntero != _punteroActivo) return;
    _punteroActivo = null;
    // Tanto al soltar como al cancelarse el puntero se guarda lo dibujado.
    ref.read(artistaProvider.notifier).terminarTrazo();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(artistaProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        // Sin alto fijo: el Expanded del padre da todo el alto libre.
        decoration: BoxDecoration(
          color: context.colores.surface,
          border: Border.all(color: context.colores.primaryStrong, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _tamano = Size(constraints.maxWidth, constraints.maxHeight);
            // Listener en vez de GestureDetector: no hay tolerancia ni
            // arena de gestos, el trazo empieza en el primer píxel
            // (plan 13 P2).
            return Listener(
              key: const ValueKey('lienzo_artista'),
              behavior: HitTestBehavior.opaque,
              onPointerDown: _empezar,
              onPointerMove: _mover,
              onPointerUp: (evento) => _terminar(evento.pointer),
              onPointerCancel: (evento) => _terminar(evento.pointer),
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Capa estable: repinta solo si cambia la lista.
                    CustomPaint(painter: TrazosPainter(estado.trazos)),
                    // Capa del gesto: repinta solo un trazo por frame.
                    CustomPaint(painter: TrazoActivoPainter(estado.activo)),
                    Positioned(
                      left: 12,
                      top: 8,
                      child: ExcludeSemantics(
                        child: Text(
                          'Dibuja aquí con el dedo.',
                          style: TextStyle(color: context.colores.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
