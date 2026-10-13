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
import 'saved_messages.dart';
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
    final view = ref.watch(comunicadorProvider);
    final categoryId = view.categoryId;

    return Column(
      children: [
        if (categoryId != null)
          _CategoryHeader(categoryId: categoryId)
        else if (view.showMessages)
          const _MessagesHeader(),
        Expanded(
          child: categoryId != null
              ? _CategoryView(categoryId: categoryId)
              : view.showMessages
                  ? const _MessagesView()
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

/// Cabecera de "Mis mensajes" con botón "Volver" al inicio.
class _MessagesHeader extends ConsumerWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              'Mis mensajes',
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

/// Lista de mensajes guardados: tocarlos los carga en la barra de frase.
class _MessagesView extends ConsumerWidget {
  const _MessagesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(savedMessagesProvider);

    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aún no has guardado mensajes. Crea una frase y pulsa "Guardar".',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          leading: const Icon(Icons.bookmark),
          title: Text(message.text),
          subtitle: Text('${message.pictoIds.length} pictogramas'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar mensaje',
            onPressed: () =>
                ref.read(savedMessagesProvider.notifier).remove(message.id),
          ),
          onTap: () => _cargarMensaje(context, ref, message),
        );
      },
    );
  }
}

/// Inicio del comunicador: buscador, favoritos y rejilla de categorías.
class _HomeView extends ConsumerWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return switch (catalog) {
      AsyncData(:final value) => _HomeContent(catalog: value),
      AsyncError() => const _CatalogError(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(comunicadorProvider);

    if (view.query.isNotEmpty) {
      return Column(
        children: [
          const _SearchField(),
          Expanded(child: _SearchResults(catalog: catalog, query: view.query)),
        ],
      );
    }

    final favorites = ref.watch(favoritesProvider);
    final favoritePictos = [
      for (final picto in catalog.pictograms)
        if (favorites.contains(picto.id)) picto,
    ];

    return Column(
      children: [
        const _SearchField(),
        if (favoritePictos.isNotEmpty)
          _FavoritesSection(pictos: favoritePictos)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Mantén presionado un pictograma para fijarlo en el inicio.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(child: _CategoryGrid(catalog: catalog)),
      ],
    );
  }
}

/// Buscador por palabra sobre todos los pictogramas (case-insensitive).
class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Al volver de otra vista, el texto del estado vuelve con el campo.
    _controller = TextEditingController(
      text: ref.read(comunicadorProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = ref.watch(comunicadorProvider).query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  ref.read(comunicadorProvider.notifier).setQuery(value),
              decoration: InputDecoration(
                labelText: 'Busca una palabra',
                hintText: 'Escribe una palabra',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Borrar búsqueda',
                        onPressed: () {
                          _controller.clear();
                          ref.read(comunicadorProvider.notifier).setQuery('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Mis mensajes',
            onPressed: () =>
                ref.read(comunicadorProvider.notifier).showMessages(),
          ),
        ],
      ),
    );
  }
}

/// Resultados del buscador sobre el catálogo completo.
class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.catalog, required this.query});

  final Catalog catalog;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needle = query.toLowerCase();
    final results = [
      for (final picto in catalog.pictograms)
        if (picto.label.toLowerCase().contains(needle) ||
            picto.keywords.any((word) => word.toLowerCase().contains(needle)))
          picto,
    ];

    if (results.isEmpty) {
      return Center(child: Text('No hay pictogramas para "$query".'));
    }

    return _PictoGrid(
      pictograms: results,
      emptyText: 'No hay pictogramas para "$query".',
    );
  }
}

/// Pictogramas fijados en el inicio, en fila horizontal (lazy).
class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection({required this.pictos});

  final List<Pictogram> pictos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pictos.length,
        itemBuilder: (context, index) {
          final picto = pictos[index];
          return SizedBox(
            width: 100,
            child: PictoTile(
              pictogram: picto,
              favorited: true,
              onTap: () => _onPictoTap(context, ref, picto),
              onLongPress: () => _onPictoLongPress(context, ref, picto),
            ),
          );
        },
      ),
    );
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
          emptyText: 'Esta categoría todavía no tiene pictogramas.',
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
        // 112 desbordaba con etiquetas de 2 líneas (52 de icono + 6 +
        // 2×22 de texto = 102 > 100 útiles tras el padding). 120 deja
        // margen también con el textScaler del sistema.
        mainAxisExtent: 120,
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

/// Rejilla de pictogramas; tocar agrega a la frase y habla (bajo tap),
/// mantener presionado fija o desfija el picto en el inicio.
class _PictoGrid extends ConsumerWidget {
  const _PictoGrid({required this.pictograms, required this.emptyText});

  final List<Pictogram> pictograms;
  final String emptyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pictograms.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final favorites = ref.watch(favoritesProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        // 112 desbordaba con etiquetas de 2 líneas (52 de icono + 6 +
        // 2×22 de texto = 102 > 100 útiles tras el padding). 120 deja
        // margen también con el textScaler del sistema.
        mainAxisExtent: 120,
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
          onLongPress: () => _onPictoLongPress(context, ref, picto),
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

/// Mantener presionado: fija o desfija el picto en el inicio, con aviso.
Future<void> _onPictoLongPress(
  BuildContext context,
  WidgetRef ref,
  Pictogram picto,
) async {
  await ref.read(favoritesProvider.notifier).toggle(picto.id);
  if (!context.mounted) return;

  final favorited = ref.read(favoritesProvider).contains(picto.id);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          favorited
              ? 'Pictograma fijado en el inicio'
              : 'Pictograma quitado del inicio',
        ),
      ),
    );
}

/// Tocar un mensaje guardado: recarga sus pictos en la barra de frase.
Future<void> _cargarMensaje(
  BuildContext context,
  WidgetRef ref,
  SavedMessage message,
) async {
  final catalog = await ref.read(catalogProvider.future);
  final pictos = [
    for (final id in message.pictoIds) catalog.pictogramById(id),
  ].whereType<Pictogram>().toList();
  ref.read(phraseProvider.notifier).load(pictos);
  ref.read(comunicadorProvider.notifier).goHome();
}
