import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import 'comunicador_prefs.dart';
import 'phrase_controller.dart';
import 'saved_messages.dart';
import 'speak_action.dart';

/// Barra de frase fija abajo (plan 02 §4): pictos tocados con X para
/// quitar, "Borrar todo" y "Leer" (TTS de la frase completa).
class PhraseBar extends ConsumerWidget {
  const PhraseBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phrase = ref.watch(phraseProvider);
    final speakOnTap = ref.watch(speakOnTapProvider);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(speakOnTap ? Icons.volume_up : Icons.volume_off),
                  tooltip:
                      speakOnTap ? 'Silenciar al tocar' : 'Hablar al tocar',
                  onPressed: () =>
                      ref.read(speakOnTapProvider.notifier).set(!speakOnTap),
                ),
                Expanded(
                  child: phrase.isEmpty
                      ? Text(
                          'Toca los pictogramas para crear un mensaje...',
                          style: theme.textTheme.bodyMedium,
                        )
                      : SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: phrase.length,
                            itemBuilder: (context, index) => _PhraseItem(
                              pictogram: phrase[index],
                              onRemove: () => ref
                                  .read(phraseProvider.notifier)
                                  .removeAt(index),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: phrase.isEmpty
                      ? null
                      : () => ref.read(phraseProvider.notifier).clear(),
                  child: const Text('Borrar todo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: phrase.isEmpty
                      ? null
                      : () => _guardarMensaje(context, ref, phrase),
                  child: const Text('Guardar'),
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: phrase.isEmpty
                      ? null
                      : () => speakText(context, ref, phraseText(phrase)),
                  child: const Text('Leer'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Diálogo "Guardar en mis mensajes": texto editable + pictos que lo forman.
  Future<void> _guardarMensaje(
    BuildContext context,
    WidgetRef ref,
    List<Pictogram> phrase,
  ) async {
    final controller = TextEditingController(text: phraseText(phrase));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar en mis mensajes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Mensaje'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    final text = controller.text.trim();
    controller.dispose();

    if (confirmed != true || text.isEmpty) return;

    await ref.read(savedMessagesProvider.notifier).save(
          text: text,
          pictoIds: [for (final picto in phrase) picto.id],
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Mensaje guardado')));
    }
  }
}

/// Picto dentro de la barra de frase, con X para quitarlo.
class _PhraseItem extends StatelessWidget {
  const _PhraseItem({required this.pictogram, required this.onRemove});

  final Pictogram pictogram;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: context.colores.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.colores.primaryStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: SvgPicture.asset(
                pictogram.asset,
                fit: BoxFit.contain,
                placeholderBuilder: (context) => const SizedBox(
                  width: 36,
                  height: 36,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                pictogram.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Quitar ${pictogram.label}',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
