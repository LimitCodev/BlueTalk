import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import 'rutinas_providers.dart';

/// Pictograma de un id de seed, con icono de respaldo si no existe.
///
/// Los ids del horario vienen del JSON semilla (`assets/seed/horario.json`):
/// si un picto no está en la muestra, se muestra un icono en vez de romper.
class PictoMini extends ConsumerWidget {
  const PictoMini(this.pictoId, {super.key, this.size = 40, this.semanticsLabel});

  final String? pictoId;
  final double size;

  /// Etiqueta para lectores de pantalla (el picto es una imagen: sin
  /// etiqueta, las herramientas de accesibilidad lo reportan).
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picto = pictoId == null
        ? null
        : ref.watch(pictosPorIdProvider).value?[pictoId];

    if (picto == null) {
      return Icon(
        Icons.help_outline,
        size: size * 0.7,
        color: context.colores.primaryStrong,
        semanticLabel: semanticsLabel,
      );
    }

    return SvgPicture.asset(
      picto.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
      placeholderBuilder: (context) => SizedBox(width: size, height: size),
    );
  }
}

/// Fila de una actividad: picto, hora, nombre y estado hecha/pendiente.
///
/// Toda la fila es tappable (≥48dp) y marca/desmarca la actividad con
/// feedback suave: el check cambia y aparece un aviso breve (plan 04 §1).
class ActividadTile extends ConsumerWidget {
  const ActividadTile({super.key, required this.entry, required this.hecha});

  final ScheduleEntry entry;
  final bool hecha;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _alternar(context, ref),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                PictoMini(entry.pictoId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatHora(entry.timeMinutes),
                        style: t.textTheme.bodySmall?.copyWith(
                          color: context.colores.primaryStrongText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        entry.title,
                        style: t.textTheme.titleMedium?.copyWith(
                          decoration: hecha ? TextDecoration.lineThrough : null,
                          color: hecha ? AppColors.onSuccess : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Semántica literal: "Recreo, hecha" para el lector.
                Semantics(
                  checked: hecha,
                  label: '${entry.title}, ${hecha ? 'hecha' : 'pendiente'}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hecha ? AppColors.success : context.colores.bg,
                      border: Border.all(
                        color: hecha
                            ? AppColors.onSuccess
                            : context.colores.primaryStrong,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      hecha ? Icons.check : Icons.schedule,
                      color: hecha
                          ? AppColors.onSuccess
                          : context.colores.primaryStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _alternar(BuildContext context, WidgetRef ref) async {
    final nuevoEstado = !hecha;
    await marcarActividad(ref, entry, hecha: nuevoEstado);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? '${entry.title}: hecha'
                : '${entry.title}: pendiente otra vez',
          ),
        ),
      );
  }
}
