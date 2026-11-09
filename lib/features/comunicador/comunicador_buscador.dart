import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comunicador_controller.dart';

/// Buscador por palabra sobre todos los pictogramas (case-insensitive).
class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
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
