import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../reloj.dart';

/// Estado del límite diario de juegos (plan 05 §4).
class LimiteJuegos {
  const LimiteJuegos({
    required this.minutosPorDia,
    required this.segundosUsados,
    required this.extensionMinutos,
  });

  /// Minutos permitidos por día; `0` = sin límite.
  final int minutosPorDia;

  /// Tiempo ya consumido hoy según los eventos `juego_fin`.
  final int segundosUsados;

  /// Minutos concedidos hoy con el botón «Jugar 5 minutos más».
  final int extensionMinutos;

  static const minutosDeExtension = 5;

  bool get sinLimite => minutosPorDia == 0;
  int get minutosDisponibles => minutosPorDia + extensionMinutos;
  int get minutosUsados => segundosUsados ~/ 60;
  bool get permitido => sinLimite || minutosUsados < minutosDisponibles;
  int get minutosRestantes =>
      sinLimite ? 0 : (minutosDisponibles - minutosUsados).clamp(0, 999);

  /// Quedan 5 minutos o menos: momento del aviso suave.
  bool get cercaDelTope => !sinLimite && permitido && minutosRestantes <= 5;
}

/// Límite de tiempo diario en juegos, persistido y calculado sobre
/// los eventos locales de la app.
class LimiteJuegosController extends AsyncNotifier<LimiteJuegos> {
  static const claveMinutos = 'padre_limite_juegos_min';
  static const clavePrevia = 'padre_limite_juegos_previo';
  static const claveExtension = 'padre_limite_extension';
  static const claveExtensionDia = 'padre_limite_extension_dia';

  @override
  Future<LimiteJuegos> build() => _leer();

  Future<LimiteJuegos> _leer() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final ahora = ref.read(relojProvider)();
    final minutos = prefs.getInt(claveMinutos) ?? 30;

    var extension = 0;
    if (prefs.getString(claveExtensionDia) == _dia(ahora)) {
      extension = prefs.getInt(claveExtension) ?? 0;
    }

    var segundos = 0;
    final eventos = await ref.read(usageRepoProvider).events();
    for (final evento in eventos) {
      if (evento.type == 'juego_fin' && mismoDia(evento.createdAt, ahora)) {
        segundos += (evento.data['segundos'] as num?)?.toInt() ?? 0;
      }
    }

    return LimiteJuegos(
      minutosPorDia: minutos,
      segundosUsados: segundos,
      extensionMinutos: extension,
    );
  }

  /// Enciende o apaga el límite sin perder el valor anterior.
  Future<void> setActivo(bool activo) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (activo) {
      final previo = prefs.getInt(clavePrevia) ?? 30;
      await _setMinutosPorDia(previo == 0 ? 30 : previo);
    } else {
      final actual = prefs.getInt(claveMinutos) ?? 30;
      if (actual != 0) await prefs.setInt(clavePrevia, actual);
      await _setMinutosPorDia(0);
    }
  }

  Future<void> setMinutosPorDia(int minutos) =>
      _setMinutosPorDia(minutos == 0 ? 0 : minutos.clamp(15, 240));

  Future<void> _setMinutosPorDia(int minutos) async {
    await ref.read(sharedPreferencesProvider).setInt(claveMinutos, minutos);
    state = AsyncData(await _leer());
  }

  /// Corte suave: 5 minutos más hoy, sin pantallazo rojo.
  Future<void> ampliar() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final ahora = ref.read(relojProvider)();
    final actual =
        prefs.getString(claveExtensionDia) == _dia(ahora)
            ? (prefs.getInt(claveExtension) ?? 0)
            : 0;
    await prefs.setString(claveExtensionDia, _dia(ahora));
    await prefs.setInt(
      claveExtension,
      actual + LimiteJuegos.minutosDeExtension,
    );
    state = AsyncData(await _leer());
  }

  static String _dia(DateTime fecha) =>
      '${fecha.year}-${fecha.month}-${fecha.day}';
}

final limiteJuegosProvider =
    AsyncNotifierProvider<LimiteJuegosController, LimiteJuegos>(
  LimiteJuegosController.new,
);

/// `true` si hoy todavía se puede entrar a Juegos (sin bloqueo de sección
/// ni tiempo agotado). El coordinador lo usa como guard de `/home/aprender`.
final juegosPermitidosProvider = FutureProvider<bool>((ref) async {
  final limite = await ref.watch(limiteJuegosProvider.future);
  return limite.permitido;
});

/// Secciones que un adulto puede bloquear desde Control (plan 05 §4).
class Bloqueos {
  const Bloqueos({this.juegos = false, this.entorno = false});

  final bool juegos;
  final bool entorno;
}

class BloqueosController extends Notifier<Bloqueos> {
  static const claveJuegos = 'padre_bloqueo_juegos';
  static const claveEntorno = 'padre_bloqueo_entorno';

  @override
  Bloqueos build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return Bloqueos(
      juegos: prefs.getBool(claveJuegos) ?? false,
      entorno: prefs.getBool(claveEntorno) ?? false,
    );
  }

  Future<void> setJuegos(bool value) async {
    state = Bloqueos(juegos: value, entorno: state.entorno);
    await ref.read(sharedPreferencesProvider).setBool(claveJuegos, value);
  }

  Future<void> setEntorno(bool value) async {
    state = Bloqueos(juegos: state.juegos, entorno: value);
    await ref.read(sharedPreferencesProvider).setBool(claveEntorno, value);
  }
}

final bloqueosProvider = NotifierProvider<BloqueosController, Bloqueos>(
  BloqueosController.new,
);
