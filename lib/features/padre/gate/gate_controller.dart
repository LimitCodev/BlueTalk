import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../reloj.dart';
import 'biometria.dart';
import 'pin_store.dart';

/// Fases del gate: crear el PIN (solo la primera vez), confirmarlo y
/// pedirlo para entrar.
enum GateFase { crear, confirmar, pedir }

class GateEstado {
  const GateEstado({
    required this.fase,
    this.mensaje,
    this.desbloqueado = false,
    this.bloqueo = Duration.zero,
  });

  final GateFase fase;

  /// Mensaje literal para la persona adulta (error o bloqueo).
  final String? mensaje;

  /// `true` cuando el código (o la huella) ya validó esta sesión.
  final bool desbloqueado;

  /// Espera restante tras 5 intentos fallidos.
  final Duration bloqueo;

  bool get bloqueado => bloqueo > Duration.zero;
}

/// Lógica del gate con lockout persistido (plan 05 §1).
///
/// El estado del bloqueo se lee de [PinStore] (preferencias locales), así
/// que sobrevive a un reinicio; el temporizador de la cuenta atrás vive
/// aquí y se cancela al disponer el provider.
class GateController extends Notifier<GateEstado> {
  Timer? _cuentaAtras;

  @override
  GateEstado build() {
    ref.onDispose(() => _cuentaAtras?.cancel());
    final store = _store();
    final restante = store.bloqueoRestante();
    // Bloqueo heredado (reinicio de la app): reanuda la cuenta atrás para
    // que el contador de segundos no se quede congelado en pantalla.
    if (restante > Duration.zero) _iniciarCuentaAtras();
    return GateEstado(
      fase: store.creado ? GateFase.pedir : GateFase.crear,
      bloqueo: restante,
    );
  }

  PinStore _store() => PinStore(
        ref.read(sharedPreferencesProvider),
        ahora: ref.read(relojProvider),
      );

  /// Fase crear → confirmar (el PIN vive solo en la pantalla hasta guardar).
  void pasarAConfirmar() {
    state = const GateEstado(fase: GateFase.confirmar);
  }

  /// Falló la confirmación: se vuelve a empezar con un aviso.
  void reiniciarCreacion(String mensaje) {
    state = GateEstado(fase: GateFase.crear, mensaje: mensaje);
  }

  /// Guarda la huella del PIN nuevo y deja el gate abierto.
  Future<void> crearPin(String pin) async {
    await _store().crear(pin);
    _cancelarCuentaAtras();
    state = const GateEstado(fase: GateFase.pedir, desbloqueado: true);
  }

  /// Comprueba el PIN: correcto abre, incorrecto avisa y el quinto fallo
  /// activa la espera de 60 segundos.
  Future<void> intentar(String pin) async {
    final store = _store();
    final resultado = await store.verificar(pin);

    if (resultado == VerificacionPin.correcto) {
      _cancelarCuentaAtras();
      state = const GateEstado(fase: GateFase.pedir, desbloqueado: true);
      return;
    }

    final restante = store.bloqueoRestante();
    if (restante > Duration.zero) {
      state = GateEstado(
        fase: GateFase.pedir,
        mensaje: 'Demasiados intentos. Espera ${restante.inSeconds} segundos.',
        bloqueo: restante,
      );
      _iniciarCuentaAtras();
      return;
    }

    state = const GateEstado(
      fase: GateFase.pedir,
      mensaje: 'Código incorrecto, inténtalo de nuevo.',
    );
  }

  /// Desbloqueo con huella o rostro (solo si el interruptor está activo).
  Future<void> intentarBiometria() async {
    final correcto = await ref.read(biometriaProvider).autenticar();
    if (correcto) {
      _cancelarCuentaAtras();
      state = const GateEstado(fase: GateFase.pedir, desbloqueado: true);
      return;
    }
    state = GateEstado(
      fase: GateFase.pedir,
      mensaje: 'No se pudo comprobar. Escribe tu PIN.',
      bloqueo: _store().bloqueoRestante(),
    );
  }

  /// Cierra la sesión del modo padre: toca volver a escribir el PIN.
  void bloquear() {
    final store = _store();
    final restante = store.bloqueoRestante();
    state = GateEstado(
      fase: store.creado ? GateFase.pedir : GateFase.crear,
      bloqueo: restante,
    );
    if (restante > Duration.zero) {
      _iniciarCuentaAtras();
    } else {
      _cancelarCuentaAtras();
    }
  }

  /// Cuenta atrás de 1 s para la espera del lockout.
  void _iniciarCuentaAtras() {
    if (_cuentaAtras != null) return;
    _cuentaAtras = Timer.periodic(const Duration(seconds: 1), (_) {
      final restante = _store().bloqueoRestante();
      // Si el reloj inyectado no avanza (tests con reloj congelado), los
      // segundos no cambian: sin este guard cada tick notificaría un estado
      // nuevo y un `pumpAndSettle` nunca asentaría.
      if (restante == state.bloqueo) return;
      state = restante > Duration.zero
          ? GateEstado(
              fase: GateFase.pedir,
              mensaje:
                  'Demasiados intentos. Espera ${restante.inSeconds} segundos.',
              bloqueo: restante,
            )
          : const GateEstado(fase: GateFase.pedir);
      if (restante == Duration.zero) _cancelarCuentaAtras();
    });
  }

  void _cancelarCuentaAtras() {
    _cuentaAtras?.cancel();
    _cuentaAtras = null;
  }
}

final gateProvider = NotifierProvider<GateController, GateEstado>(
  GateController.new,
);
