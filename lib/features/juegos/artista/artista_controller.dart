import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../data/models/models.dart';
import 'artista_dibujos.dart';

/// Pinceles de la paleta pastel (plan 00 §4) con nombre literal.
List<(String, Color)> get pincelesPastel => const [
      ('Celeste', Color(0xFF7FC9EA)),
      ('Verde', Color(0xFFA8DDB5)),
      ('Amarillo', Color(0xFFF6D97A)),
      ('Rosa', Color(0xFFF4B8C6)),
      ('Naranja', Color(0xFFF7C59F)),
      ('Morado', Color(0xFFC9B8E8)),
      ('Marrón', Color(0xFFB08968)),
      ('Negro', Color(0xFF1F3A44)),
    ];

/// Grosor fino del trazo, en píxeles lógicos sobre el lienzo completo.
const grosorFino = 4.0;
const grosorMedio = 9.0;
const grosorGrueso = 18.0;

/// Estado del artista.
class ArtistaEstado {
  const ArtistaEstado({
    this.color = const Color(0xFF1F3A44),
    this.grosor = grosorMedio,
    this.goma = false,
    this.trazos = const [],
    this.activo,
  });

  /// Color del pincel activo (irrelevante con la goma).
  final Color color;
  final double grosor;

  /// Modo goma: los trazos se pintan con el color del fondo del lienzo.
  final bool goma;

  /// Trazos ya terminados (pila de deshacer).
  final List<Trazo> trazos;

  /// Trazo en curso; null cuando no se está dibujando.
  final Trazo? activo;

  ArtistaEstado copyWith({
    Color? color,
    double? grosor,
    bool? goma,
    List<Trazo>? trazos,
    Trazo? activo,
    bool limpiarActivo = false,
  }) =>
      ArtistaEstado(
        color: color ?? this.color,
        grosor: grosor ?? this.grosor,
        goma: goma ?? this.goma,
        trazos: trazos ?? this.trazos,
        activo: limpiarActivo ? null : activo ?? this.activo,
      );
}

/// Controlador del artista: pinceles, goma, deshacer y guardar.
///
/// Los puntos se guardan normalizados (0–1) respecto al lienzo, así un
/// dibujo guardado se ve igual en cualquier pantalla y en las
/// miniaturas de la galería.
class ArtistaController extends Notifier<ArtistaEstado> {
  @override
  ArtistaEstado build() => const ArtistaEstado();

  void elegirColor(Color color) =>
      state = state.copyWith(color: color, goma: false);

  void elegirGrosor(double grosor) => state = state.copyWith(grosor: grosor);

  void alternarGoma() => state = state.copyWith(goma: !state.goma);

  /// Empieza un trazo en el punto [punto] del lienzo de [tamano].
  void empezarTrazo(Offset punto, Size tamano) {
    final color = state.goma ? const Color(0xFFFFFFFF) : state.color;
    state = state.copyWith(
      activo: Trazo(
        color: color.toARGB32(),
        grosor: state.grosor * 1000 / tamano.width,
        puntos: [_normalizar(punto, tamano)],
      ),
    );
  }

  /// Continúa el trazo actual; ignora puntos casi pegados al anterior
  /// para no engordar el path sin aportar nada (gama baja).
  void continuarTrazo(Offset punto, Size tamano) {
    final activo = state.activo;
    if (activo == null || activo.puntos.isEmpty) return;
    final anterior = activo.puntos.last;
    final nuevo = _normalizar(punto, tamano);
    final distancia = (nuevo - anterior).distance * tamano.width;
    if (distancia < 1.5) return;
    // Tope de puntos por dibujo (plan 11 §1.3.5): el JSON de la galería
    // no crece sin límite aunque el dibujo no pare nunca.
    if (_puntosDelDibujo() >= GaleriaController.maxPuntosPorDibujo) return;

    state = state.copyWith(
      activo: Trazo(
        color: activo.color,
        grosor: activo.grosor,
        puntos: [...activo.puntos, nuevo],
      ),
    );
  }

  /// Termina el trazo y lo apila para deshacer.
  void terminarTrazo() {
    final activo = state.activo;
    if (activo == null) return;
    state = state.copyWith(
      trazos: [...state.trazos, activo],
      limpiarActivo: true,
    );
  }

  /// Deshace el último trazo (el en curso se descarta primero).
  void deshacer() {
    if (state.activo != null) {
      state = state.copyWith(limpiarActivo: true);
      return;
    }
    if (state.trazos.isEmpty) return;
    state = state.copyWith(trazos: [...state.trazos]..removeLast());
  }

  /// Guarda el dibujo y registra el uso (plan 03 §6). Devuelve `false`
  /// si la galería está llena: no se guarda ni se registra nada.
  Future<bool> guardar() async {
    if (state.trazos.isEmpty) return false;
    final guardado = await ref
        .read(galeriaDibujosProvider.notifier)
        .guardar(state.trazos);
    if (!guardado) return false;
    try {
      await ref.read(usageRepoProvider).record(
            UsageEvent(
              id: 'artista_dibujo_${DateTime.now().microsecondsSinceEpoch}',
              type: 'dibujo_guardado',
              createdAt: DateTime.now(),
              data: {'juego': 'artista'},
            ),
          );
    } catch (_) {
      // El registro de uso es solo para el panel del modo padre: si
      // falla, el dibujo ya está guardado y nada importante se pierde.
    }
    return true;
  }

  /// Puntos contados en el dibujo en curso (trazos terminados + actual).
  int _puntosDelDibujo() {
    var total = state.activo?.puntos.length ?? 0;
    for (final trazo in state.trazos) {
      total += trazo.puntos.length;
      if (total > GaleriaController.maxPuntosPorDibujo) return total;
    }
    return total;
  }

  /// Carga un dibujo de la galería en el lienzo para seguir editando.
  void cargarDibujo(Dibujo dibujo) {
    state = state.copyWith(trazos: [...dibujo.trazos], limpiarActivo: true);
  }

  Offset _normalizar(Offset punto, Size tamano) => Offset(
        (punto.dx / tamano.width).clamp(0.0, 1.0),
        (punto.dy / tamano.height).clamp(0.0, 1.0),
      );
}

/// Controlador del artista.
final artistaProvider = NotifierProvider<ArtistaController, ArtistaEstado>(
  ArtistaController.new,
);
