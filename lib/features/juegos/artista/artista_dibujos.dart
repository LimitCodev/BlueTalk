import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';

/// Trazo del artista: color, grosor y puntos normalizados (0–1 respecto
/// al lienzo, en un espacio de referencia de 1000 para el grosor).
///
/// Los puntos normalizados hacen que un dibujo guardado se vea igual en
/// cualquier pantalla y en las miniaturas de la galería.
class Trazo {
  const Trazo({
    required this.color,
    required this.grosor,
    required this.puntos,
  });

  /// Color ARGB empaquetado como int (JSON-friendly).
  final int color;

  /// Grosor en el espacio de referencia 1000.
  final double grosor;
  final List<Offset> puntos;

  Map<String, dynamic> toMap() => {
        'color': color,
        'grosor': grosor,
        'puntos': [
          for (final p in puntos) [p.dx, p.dy],
        ],
      };

  factory Trazo.fromMap(Map<String, dynamic> map) => Trazo(
        color: (map['color'] as num).toInt(),
        grosor: (map['grosor'] as num).toDouble(),
        puntos: [
          for (final row in (map['puntos'] as List))
            Offset(
              (row[0] as num).toDouble(),
              (row[1] as num).toDouble(),
            ),
        ],
      );
}

/// Dibujo guardado en la galería local del dispositivo.
class Dibujo {
  const Dibujo({required this.id, required this.trazos});

  final String id;
  final List<Trazo> trazos;

  Map<String, dynamic> toMap() => {
        'id': id,
        'trazos': [for (final t in trazos) t.toMap()],
      };

  factory Dibujo.fromMap(Map<String, dynamic> map) => Dibujo(
        id: map['id'] as String,
        trazos: [
          for (final row in (map['trazos'] as List? ?? const []))
            Trazo.fromMap(Map<String, dynamic>.from(row as Map)),
        ],
      );
}

/// Galería local de dibujos: la lista de trazos se persiste como JSON en
/// SharedPreferences (misma decisión que "mis mensajes" del comunicador;
/// migrar a Drift cuando `lib/data/local` lo soporte, plan 03 §4).
///
/// La escritura es un solo string JSON con la lista entera; cabe en
/// preferencias sin drama gracias a los topes (plan 11 §1.3.5).
class GaleriaController extends Notifier<List<Dibujo>> {
  /// Tope de dibujos: al llegar, la pantalla avisa en lenguaje literal y
  /// pide borrar uno. **Nunca se borra nada a escondidas.**
  static const maxDibujos = 30;

  /// Tope de puntos por dibujo: aunque se dibuje muchísimo, el JSON de
  /// la galería no crece sin límite y el arranque no se ralentiza.
  static const maxPuntosPorDibujo = 3000;

  static const _clave = 'bluetalk_artista_dibujos';

  @override
  List<Dibujo> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_clave);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];
      final cargados = [
        for (final row in decoded)
          if (row is Map) Dibujo.fromMap(Map<String, dynamic>.from(row)),
      ];
      // Migración del tope anterior (50): se quedan los más recientes.
      return cargados.length > maxDibujos
          ? cargados.sublist(cargados.length - maxDibujos)
          : cargados;
    } catch (_) {
      // Preferencias corruptas (JSON o fila ilegible): galería limpia.
      return const [];
    }
  }

  /// Guarda al final de la galería (lo más reciente al final).
  /// Devuelve `false` si está llena: no se guarda ni se borra nada.
  Future<bool> guardar(List<Trazo> trazos) async {
    if (state.length >= maxDibujos) return false;
    final dibujo = Dibujo(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      trazos: trazos,
    );
    state = [...state, dibujo];
    await _persistir();
    return true;
  }

  Future<void> borrar(String id) async {
    state = [for (final d in state) if (d.id != id) d];
    await _persistir();
  }

  Future<void> _persistir() async {
    await ref.read(sharedPreferencesProvider).setString(
          _clave,
          jsonEncode([for (final d in state) d.toMap()]),
        );
  }
}

/// Dibujos guardados en la galería local.
final galeriaDibujosProvider =
    NotifierProvider<GaleriaController, List<Dibujo>>(
  GaleriaController.new,
);
