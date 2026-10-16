import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../cabecera_juego.dart';
import 'artista_canvas.dart';
import 'artista_controller.dart';
import 'artista_dibujos.dart';

/// Artista (plan 03 §4): lienzo con pinceles pastel, grosor, goma,
/// deshacer y galería local de dibujos guardados.
class ArtistaScreen extends ConsumerWidget {
  const ArtistaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        CabeceraJuego('Artista'),
        _BarraHerramientas(),
        // El lienzo ocupa todo el alto libre: no hay nada que desplazar,
        // así un arrastre vertical nunca compite con un scroll (plan 13 P2).
        Expanded(child: _Lienzo()),
      ],
    );
  }
}

/// Barra de herramientas compacta arriba del lienzo (plan 13 P2):
/// colores, grosor, goma, deshacer, guardar, galería y borrar todo (≥48dp).
class _BarraHerramientas extends ConsumerStatefulWidget {
  const _BarraHerramientas();

  @override
  ConsumerState<_BarraHerramientas> createState() => _BarraHerramientasState();
}

class _BarraHerramientasState extends ConsumerState<_BarraHerramientas> {
  /// Segundo toque pendiente en «Borrar todo»: sin diálogo largo, el
  /// propio botón pide la confirmación (plan 13 P2).
  bool _confirmandoBorrado = false;

  /// Cualquier otra acción de la barra cancela una confirmación pendiente.
  void _cancelarConfirmacion() {
    if (_confirmandoBorrado) setState(() => _confirmandoBorrado = false);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(artistaProvider);
    final controller = ref.read(artistaProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (nombre, color) in pincelesPastel)
                  _BotonColor(
                    nombre: nombre,
                    color: color,
                    seleccionado: !estado.goma && estado.color == color,
                    onTap: () {
                      _cancelarConfirmacion();
                      controller.elegirColor(color);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BotonGrosor(
                etiqueta: 'Fino',
                grosor: grosorFino,
                activo: estado.grosor == grosorFino,
                onTap: () {
                  _cancelarConfirmacion();
                  controller.elegirGrosor(grosorFino);
                },
              ),
              _BotonGrosor(
                etiqueta: 'Medio',
                grosor: grosorMedio,
                activo: estado.grosor == grosorMedio,
                onTap: () {
                  _cancelarConfirmacion();
                  controller.elegirGrosor(grosorMedio);
                },
              ),
              _BotonGrosor(
                etiqueta: 'Grosor',
                grosor: grosorGrueso,
                activo: estado.grosor == grosorGrueso,
                onTap: () {
                  _cancelarConfirmacion();
                  controller.elegirGrosor(grosorGrueso);
                },
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () {
                  _cancelarConfirmacion();
                  controller.alternarGoma();
                },
                icon: Icon(estado.goma ? Icons.cleaning_services : Icons.brush),
                label: Text(estado.goma ? 'Goma activa' : 'Goma'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: estado.trazos.isEmpty && estado.activo == null
                    ? null
                    : () {
                        _cancelarConfirmacion();
                        controller.deshacer();
                      },
                icon: const Icon(Icons.undo),
                label: const Text('Deshacer'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: estado.trazos.isEmpty
                    ? null
                    : () async {
                        _cancelarConfirmacion();
                        final guardado = await controller.guardar();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                guardado
                                    ? 'Dibujo guardado en Mis dibujos'
                                    : 'Tu galería ya tiene ${GaleriaController.maxDibujos} dibujos. '
                                          'Borra uno de Mis dibujos para guardar este.',
                              ),
                            ),
                          );
                      },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
              // La galería vive en una hoja inferior: en pantalla solo
              // queda el lienzo, sin nada que desplazar (plan 13 P2).
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () {
                  _cancelarConfirmacion();
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (context) =>
                        const SafeArea(child: _GaleriaLocal()),
                  );
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Mis dibujos'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  backgroundColor: _confirmandoBorrado
                      ? context.colores.primary
                      : null,
                  foregroundColor: _confirmandoBorrado
                      ? context.colores.primaryInk
                      : null,
                ),
                onPressed: estado.trazos.isEmpty && estado.activo == null
                    ? null
                    : () {
                        if (!_confirmandoBorrado) {
                          setState(() => _confirmandoBorrado = true);
                          return;
                        }
                        setState(() => _confirmandoBorrado = false);
                        controller.borrarTodo();
                      },
                icon: Icon(
                  _confirmandoBorrado
                      ? Icons.warning_amber_outlined
                      : Icons.delete_outline,
                ),
                label: Text(_confirmandoBorrado ? '¿Seguro?' : 'Borrar todo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Casilla de color de la paleta pastel (target ≥48dp).
class _BotonColor extends StatelessWidget {
  const _BotonColor({
    required this.nombre,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final String nombre;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Color $nombre',
      child: InkWell(
        key: ValueKey('color_$nombre'),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: seleccionado
                    ? context.colores.primaryStrong
                    : context.colores.primary,
                width: seleccionado ? 4 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de grosor con vista previa del trazo (target ≥48dp).
class _BotonGrosor extends StatelessWidget {
  const _BotonGrosor({
    required this.etiqueta,
    required this.grosor,
    required this.activo,
    required this.onTap,
  });

  final String etiqueta;
  final double grosor;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: activo
              ? context.colores.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: context.colores.primaryInk,
        ),
        onPressed: onTap,
        icon: Icon(Icons.circle, size: grosor.clamp(8.0, 20.0)),
        label: Text(etiqueta),
      ),
    );
  }
}

/// El lienzo: dos capas apiladas (trazos terminados + trazo activo) para
/// que arrastrar solo repinta un path (plan 03 §4).
class _Lienzo extends ConsumerStatefulWidget {
  const _Lienzo();

  @override
  ConsumerState<_Lienzo> createState() => _LienzoState();
}

class _LienzoState extends ConsumerState<_Lienzo> {
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

/// Galería local "Mis dibujos": miniaturas de los dibujos guardados.
class _GaleriaLocal extends ConsumerWidget {
  const _GaleriaLocal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dibujos = ref.watch(galeriaDibujosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Mis dibujos'),
        if (dibujos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Todavía no has guardado dibujos. Dibuja y pulsa "Guardar".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dibujos.length,
              itemBuilder: (context, index) {
                final dibujo = dibujos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      InkWell(
                        key: ValueKey('dibujo_${dibujo.id}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          ref
                              .read(artistaProvider.notifier)
                              .cargarDibujo(dibujo);
                          // La galería vive en una hoja inferior: al cargar
                          // el dibujo se cierra para volver a ver el lienzo.
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 96,
                          height: 72,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colores.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: TrazosPainter(dibujo.trazos),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Borrar dibujo',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(galeriaDibujosProvider.notifier)
                            .borrar(dibujo.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
