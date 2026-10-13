import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/di.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import 'comunicador_catalog.dart';
import 'comunicador_controller.dart';
import 'comunicador_prefs.dart';
import 'phrase_bar.dart';
import 'phrase_controller.dart';
import 'picto_tile.dart';
import 'speak_action.dart';

/// Comunicador AAC (plan 02): categorías, pictogramas offline, barra de
/// frase y voz. Cuerpo de la pestaña "Comunicar" del shell.
///
/// Autocontenido: su navegación (inicio, categoría, mis mensajes) es
/// interna, sin rutas propias, para no acoplarse al router raíz.
class ComunicadorScreen extends ConsumerWidget {
  const ComunicadorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = ref.watch(comunicadorProvider).categoryId;

    return Column(
      children: [
        if (categoryId != null) _CategoryHeader(categoryId: categoryId),
        Expanded(
          child: categoryId != null
              ? _CategoryView(categoryId: categoryId)
              : const _HomeView(),
        ),
        const PhraseBar(),
      ],
    );
  }
}

/// Cabecera de categoría con botón "Volver" (≥48dp) al inicio.
class _CategoryHeader extends ConsumerWidget {
  const _CategoryHeader({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final name = catalog?.categories
        .firstWhere(
          (category) => category.id == categoryId,
          orElse: () => Category(id: categoryId, name: categoryId, icon: ''),
        )
        .name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 48),
            ),
            onPressed: () => ref.read(comunicadorProvider.notifier).goHome(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name ?? categoryId,
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

/// Inicio del comunicador: rejilla de categorías (lazy).
class _HomeView extends ConsumerWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return switch (catalog) {
      AsyncData(:final value) => _CategoryGrid(catalog: value),
      AsyncError() => const _CatalogError(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Vista de una categoría: rejilla de sus pictogramas (lazy).
class _CategoryView extends ConsumerWidget {
  const _CategoryView({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return switch (catalog) {
      AsyncData(:final value) => _PictoGrid(
          pictograms: value.pictogramsOf(categoryId),
        ),
      AsyncError() => const _CatalogError(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Rejilla de categorías con su icono y nombre.
class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = catalog.categories;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        mainAxisExtent: 112,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final iconAsset = catalog.iconAssetOf(category);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => ref
              .read(comunicadorProvider.notifier)
              .openCategory(category.id),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: iconAsset == null
                      ? const Icon(
                          Icons.grid_view_rounded,
                          size: 44,
                          color: AppColors.primaryStrong,
                        )
                      : SvgPicture.asset(
                          iconAsset,
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => const SizedBox(
                            width: 52,
                            height: 52,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Rejilla de pictogramas; tocar agrega a la frase y habla (bajo tap).
class _PictoGrid extends ConsumerWidget {
  const _PictoGrid({required this.pictograms});

  final List<Pictogram> pictograms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pictograms.isEmpty) {
      return const Center(
        child: Text('Esta categoría todavía no tiene pictogramas.'),
      );
    }

    final favorites = ref.watch(favoritesProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        mainAxisExtent: 112,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pictograms.length,
      itemBuilder: (context, index) {
        final picto = pictograms[index];
        return PictoTile(
          pictogram: picto,
          favorited: favorites.contains(picto.id),
          onTap: () => _onPictoTap(context, ref, picto),
        );
      },
    );
  }
}

/// Error de carga de assets (plan 02 §8): aviso literal + reintento.
class _CatalogError extends ConsumerWidget {
  const _CatalogError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se pudieron cargar los pictogramas.'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.invalidate(catalogProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Tocar un picto: agrega a la frase, registra el uso y habla si está activo.
Future<void> _onPictoTap(
  BuildContext context,
  WidgetRef ref,
  Pictogram picto,
) async {
  ref.read(phraseProvider.notifier).add(picto);

  // Alimenta el dashboard del modo padre (plan 02 §6).
  unawaited(
    ref.read(usageRepoProvider).record(
          UsageEvent(
            id: '${picto.id}_${DateTime.now().microsecondsSinceEpoch}',
            type: 'picto_tap',
            createdAt: DateTime.now(),
            data: {'categoryId': picto.categoryId, 'pictoId': picto.id},
          ),
        ),
  );

  if (ref.read(speakOnTapProvider)) {
    await speakText(context, ref, picto.label);
  }
}
