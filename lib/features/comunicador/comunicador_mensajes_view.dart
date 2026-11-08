import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'saved_messages.dart';
import 'comunicador_acciones.dart';

/// Lista de mensajes guardados: tocarlos los carga en la barra de frase.
class MessagesView extends ConsumerWidget {
  const MessagesView({super.key});

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
          onTap: () => cargarMensaje(context, ref, message),
        );
      },
    );
  }
}
