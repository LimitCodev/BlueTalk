import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../reloj.dart';
import 'textos_legales.dart';

/// Aceptación registrada de los documentos legales (fecha + versión).
class AceptacionLegal {
  const AceptacionLegal({
    required this.version,
    required this.fecha,
    required this.consentimientoPadre,
  });

  final String version;
  final DateTime fecha;

  /// Consentimiento parental explícito (checkbox marcado al aceptar).
  final bool consentimientoPadre;

  Map<String, dynamic> toMap() => {
        'version': version,
        'fecha': fecha.millisecondsSinceEpoch,
        'consentimientoPadre': consentimientoPadre,
      };

  factory AceptacionLegal.fromMap(Map<String, dynamic> map) => AceptacionLegal(
        version: map['version'] as String? ?? '',
        fecha: DateTime.fromMillisecondsSinceEpoch(
          (map['fecha'] as num?)?.toInt() ?? 0,
        ),
        consentimientoPadre: map['consentimientoPadre'] as bool? ?? false,
      );
}

/// Control de la aceptación de Términos y Privacidad.
///
/// `null` = sin aceptar → el modo padre no deja pasar (plan 05 §6).
/// La aceptación se guarda con su versión para volver a pedirla cuando los
/// documentos cambien.
class LegalController extends Notifier<AceptacionLegal?> {
  static const prefKey = 'padre_legal_aceptacion';

  @override
  AceptacionLegal? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(prefKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final aceptacion = AceptacionLegal.fromMap(decoded);
      return aceptacion.version.isEmpty ? null : aceptacion;
    } catch (_) {
      // Preferencias corruptas: se vuelve a pedir la aceptación.
      return null;
    }
  }

  Future<void> aceptar() async {
    final aceptacion = AceptacionLegal(
      version: versionLegal,
      fecha: ref.read(relojProvider)(),
      consentimientoPadre: true,
    );
    state = aceptacion;
    await ref
        .read(sharedPreferencesProvider)
        .setString(prefKey, jsonEncode(aceptacion.toMap()));
  }

  Future<void> rechazar() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(prefKey);
  }
}

final legalProvider =
    NotifierProvider<LegalController, AceptacionLegal?>(LegalController.new);
