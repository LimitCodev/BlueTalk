import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../avance_juegos.dart';
import '../juegos_catalog.dart';
import 'memoria_controller.dart';

/// Juego memoria (plan 03 §2): selector de niveles y tablero de parejas.
class MemoriaScreen extends ConsumerWidget {
  const MemoriaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(memoriaProvider);

    return switch (estado) {
      AsyncData(:final value) => value.enTablero
          ? _Tablero(estado: value)
          : _SelectorNiveles(desbloqueado: value.desbloqueado),
      AsyncError() => const Center(
          child: Text('No se pudo cargar el juego.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Selector de niveles: los desbloqueados se pueden tocar; el resto,
/// muestrado un candado. Literal del plan: "Cada nivel es más difícil 💙".
class _SelectorNiveles extends ConsumerWidget {
  const _SelectorNiveles({required this.desbloqueado});

  final int desbloqueado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'Cada nivel es más difícil 💙',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var nivel = 1; nivel <= memoriaMaxNiveles; nivel++)
                  _BotonNivel(nivel: nivel, desbloqueado: desbloqueado),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón de un nivel (≥48dp); los bloqueados están apagados.
class _BotonNivel extends ConsumerWidget {
  const _BotonNivel({required this.nivel, required this.desbloqueado});

  final int nivel;
  final int desbloqueado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desbloqueadoNivel = nivel <= desbloqueado;

    return SizedBox(
      width: 104,
      height: 56,
      child: desbloqueadoNivel
          ? FilledButton(
              onPressed: () =>
                  ref.read(memoriaProvider.notifier).empezarNivel(nivel),
              child: Text('Nivel $nivel'),
            )
          : OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Nivel $nivel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Tablero de parejas del nivel activo.
class _Tablero extends ConsumerWidget {
  const _Tablero({required this.estado});

  final MemoriaViewState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivel = estado.nivel!;
    final siguienteDisponible = nivel < memoriaMaxNiveles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              Text('Nivel $nivel',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Text(
                'Parejas: ${estado.descubiertas.length ~/ 2} de ${estado.parejas}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 4,
              // Ficha: icono 52 + 4 + 1 línea de texto 20 + 12 de padding
              // = 88; 104 deja margen con el textScaler del sistema.
              mainAxisExtent: 104,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                for (var index = 0; index < estado.tablero.length; index++)
                  _Ficha(index: index, estado: estado),
              ],
            ),
          ),
        ),
        if (estado.completado)
          _PanelCompletado(nivel: nivel, siguiente: siguienteDisponible),
      ],
    );
  }
}

/// Ficha del tablero: feedback por estado (color/borde), sin parpadeos.
class _Ficha extends ConsumerWidget {
  const _Ficha({required this.index, required this.estado});

  final int index;
  final MemoriaViewState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(pictosProvider).value;
    final descubierta = estado.descubiertas.contains(index);
    final fallida = estado.fallas.contains(index);
    final levantada = estado.seleccion.contains(index) || descubierta;

    final picto = levantada && catalog != null
        ? _pictoPorId(catalog, estado.tablero[index])
        : null;

    final (colorBorde, colorFondo) = switch ((descubierta, fallida)) {
      (true, _) => (AppColors.onSuccess, AppColors.success),
      (_, true) => (AppColors.onError, AppColors.error),
      _ => (AppColors.primaryStrong, AppColors.surface),
    };

    return Semantics(
      button: true,
      label: picto == null ? 'Ficha tapada, toca para ver' : picto.label,
      child: InkWell(
        key: ValueKey('memoria_ficha_$index'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(memoriaProvider.notifier).tocarFicha(index),
        child: Container(
          decoration: BoxDecoration(
            color: descubierta || fallida
                ? colorFondo
                : levantada
                    ? AppColors.surface
                    : AppColors.primary.withValues(alpha: 0.35),
            border: Border.all(color: colorBorde, width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(6),
          child: picto == null
              ? const Center(
                  child: Icon(
                    Icons.extension,
                    size: 40,
                    color: AppColors.primaryStrong,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      picto.asset,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      // Sin spinner animado: solo un espacio neutro al cargar.
                      placeholderBuilder: (context) => const SizedBox(
                        width: 52,
                        height: 52,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      picto.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Aviso de nivel completado con la salida al siguiente nivel.
class _PanelCompletado extends ConsumerWidget {
  const _PanelCompletado({required this.nivel, required this.siguiente});

  final int nivel;
  final bool siguiente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success,
        border: Border.all(color: AppColors.onSuccess, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '¡Nivel completado! 🎉',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (siguiente)
                FilledButton(
                  onPressed: () => ref
                      .read(memoriaProvider.notifier)
                      .empezarNivel(nivel + 1),
                  child: Text('Jugar nivel ${nivel + 1}'),
                ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(memoriaProvider.notifier).volverAlSelector(),
                child: const Text('Elegir otro nivel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pictograma por id desde el catálogo cargado.
Pictogram? _pictoPorId(List<Pictogram> pictos, String id) {
  for (final picto in pictos) {
    if (picto.id == id) return picto;
  }
  return null;
}
