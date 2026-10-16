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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BarraHerramientas(),
                _Lienzo(),
                _GaleriaLocal(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra de herramientas: colores, grosor, goma y deshacer (≥48dp).
class _BarraHerramientas extends ConsumerWidget {
  const _BarraHerramientas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onTap: () => controller.elegirColor(color),
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
                onTap: () => controller.elegirGrosor(grosorFino),
              ),
              _BotonGrosor(
                etiqueta: 'Medio',
                grosor: grosorMedio,
                activo: estado.grosor == grosorMedio,
                onTap: () => controller.elegirGrosor(grosorMedio),
              ),
              _BotonGrosor(
                etiqueta: 'Grosor',
                grosor: grosorGrueso,
                activo: estado.grosor == grosorGrueso,
                onTap: () => controller.elegirGrosor(grosorGrueso),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: controller.alternarGoma,
                icon: Icon(
                  estado.goma ? Icons.cleaning_services : Icons.brush,
                ),
                label: Text(estado.goma ? 'Goma activa' : 'Goma'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed:
                    estado.trazos.isEmpty && estado.activo == null
                        ? null
                        : controller.deshacer,
                icon: const Icon(Icons.undo),
                label: const Text('Deshacer'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: estado.trazos.isEmpty
                    ? null
                    : () async {
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
                    ? AppColors.primaryStrong
                    : AppColors.primary,
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
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: AppColors.primaryInk,
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

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(artistaProvider);
    final controller = ref.read(artistaProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.primaryStrong, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _tamano = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              key: const ValueKey('lienzo_artista'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) => controller.empezarTrazo(
                details.localPosition,
                _tamano,
              ),
              onPanUpdate: (details) => controller.continuarTrazo(
                details.localPosition,
                _tamano,
              ),
              onPanEnd: (_) => controller.terminarTrazo(),
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Capa estable: repinta solo si cambia la lista.
                    CustomPaint(painter: TrazosPainter(estado.trazos)),
                    // Capa del gesto: repinta solo un trazo por frame.
                    CustomPaint(painter: TrazoActivoPainter(estado.activo)),
                    const Positioned(
                      left: 12,
                      top: 8,
                      child: ExcludeSemantics(
                        child: Text(
                          'Dibuja aquí con el dedo.',
                          style: TextStyle(color: AppColors.text),
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
                        onTap: () => ref
                            .read(artistaProvider.notifier)
                            .cargarDibujo(dibujo),
                        child: Container(
                          width: 96,
                          height: 72,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
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
