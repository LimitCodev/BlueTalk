import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

/// Mensaje guardado: texto + los ids de sus pictogramas.
class SavedMessage {
  const SavedMessage({
    required this.id,
    required this.text,
    required this.pictoIds,
    required this.createdAt,
  });

  final String id;
  final String text;
  final List<String> pictoIds;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'pictoIds': pictoIds,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory SavedMessage.fromMap(Map<String, dynamic> map) => SavedMessage(
        id: map['id'] as String,
        text: map['text'] as String? ?? '',
        pictoIds: (map['pictoIds'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
}

/// "Mis mensajes": guardado temporal en SharedPreferences.
///
/// Pendiente de migrar a Drift en `lib/data/local` cuando ese setup exista
/// (plan 02 §6); la interfaz de la feature no cambiará.
class SavedMessagesController extends Notifier<List<SavedMessage>> {
  static const prefKey = 'bluetalk_saved_messages';

  @override
  List<SavedMessage> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(prefKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];
      return [
        for (final row in decoded)
          if (row is Map)
            SavedMessage.fromMap(Map<String, dynamic>.from(row)),
      ];
    } on FormatException {
      // Preferencias corruptas (escritura parcial): lista limpia en vez de
      // romper la pantalla del niño que observa este provider.
      return const [];
    } on TypeError {
      // Esquema cambiado o fila inesperada: también se empieza de cero.
      return const [];
    }
  }

  Future<void> save({
    required String text,
    required List<String> pictoIds,
  }) async {
    final message = SavedMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      pictoIds: pictoIds,
      createdAt: DateTime.now(),
    );
    state = [message, ...state];
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [for (final message in state) if (message.id != id) message];
    await _persist();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode([for (final message in state) message.toMap()]);
    await ref.read(sharedPreferencesProvider).setString(prefKey, encoded);
  }
}

/// Mensajes guardados por el niño (más recientes primero).
final savedMessagesProvider =
    NotifierProvider<SavedMessagesController, List<SavedMessage>>(
  SavedMessagesController.new,
);
