import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../reloj.dart';
import 'biometria.dart';
import 'pin_store.dart';

/// Fases del gate: crear el PIN (solo la primera vez), confirmarlo y
/// pedirlo para entrar.
enum GateFase { crear, confirmar, pedir }

/// Derivación de la huella del PIN: en producción corre en un isolate para
/// no congelar la UI (plan 11 §1.2); los tests de widget la sustituyen
/// porque `Isolate.run` no completa dentro de `testWidgets` (FakeAsync,
/// plan 12 §0.2).
final derivadorPinProvider = Provider<DerivadorPin>(
  (ref) => const DerivadorPinAislamiento(),
);

class GateEstado {
  const GateEstado({
    required this.fase,
    this.mensaje,
    this.desbloqueado = false,
    this.bloqueo = Duration.zero,
    this.longitud = PinStore.longitudNueva,
  });

  final GateFase fase;

  /// Mensaje literal para la persona adulta (error o bloqueo).
  final String? mensaje;

  /// `true` cuando el código (o la huella) ya validó esta sesión.
  final bool desbloqueado;

  /// Espera restante tras 5 intentos fallidos.
  final Duration bloqueo;

  /// Dígitos que debe tener el código en esta fase: 6 para crear o
  /// confirmar; los PIN creados en versiones anteriores piden los suyos.
  final int longitud;

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
      longitud: store.creado ? store.longitudGuardada : PinStore.longitudNueva,
    );
  }

  PinStore _store() => PinStore(
        ref.read(sharedPreferencesProvider),
        ahora: ref.read(relojProvider),
        derivador: ref.read(derivadorPinProvider),
      );

  /// Estado de la fase de petición, con la longitud del PIN guardado (los
  /// PIN de 4 dígitos de versiones anteriores siguen pidiendo los suyos).
  GateEstado _estadoPedir({
    String? mensaje,
    Duration bloqueo = Duration.zero,
    bool desbloqueado = false,
  }) {
    final store = _store();
    return GateEstado(
      fase: GateFase.pedir,
      mensaje: mensaje,
      bloqueo: bloqueo,
      desbloqueado: desbloqueado,
      longitud: store.creado ? store.longitudGuardada : PinStore.longitudNueva,
    );
  }

  /// Fase crear → confirmar (el PIN vive solo en la pantalla hasta guardar).
  void pasarAConfirmar() {
    state = const GateEstado(fase: GateFase.confirmar);
  }

  /// Falló la confirmación: se vuelve a empezar con un aviso.
  void reiniciarCreacion(String mensaje) {
    state = GateEstado(fase: GateFase.crear, mensaje: mensaje);
  }

  /// Guarda la huella del PIN nuevo (6 dígitos) y deja el gate abierto.
  Future<void> crearPin(String pin) async {
    await _store().crear(pin);
    _cancelarCuentaAtras();
    state = _estadoPedir(desbloqueado: true);
  }

  /// Comprueba el PIN: correcto abre, incorrecto avisa y cada ciclo de 5
  /// fallos sube la espera del bloqueo escalonado.
  Future<void> intentar(String pin) async {
    final store = _store();
    final resultado = await store.verificar(pin);

    if (resultado == VerificacionPin.correcto) {
      _cancelarCuentaAtras();
      state = _estadoPedir(desbloqueado: true);
      return;
    }

    final restante = store.bloqueoRestante();
    if (restante > Duration.zero) {
      state = _estadoPedir(
        mensaje: 'Demasiados intentos. Espera ${restante.inSeconds} segundos.',
        bloqueo: restante,
      );
      _iniciarCuentaAtras();
      return;
    }

    state = _estadoPedir(mensaje: 'Código incorrecto, inténtalo de nuevo.');
  }

  /// Desbloqueo con huella o rostro (solo si el interruptor está activo).
  Future<void> intentarBiometria() async {
    final correcto = await ref.read(biometriaProvider).autenticar();
    if (correcto) {
      _cancelarCuentaAtras();
      state = _estadoPedir(desbloqueado: true);
      return;
    }
    state = _estadoPedir(
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
      longitud: store.creado ? store.longitudGuardada : PinStore.longitudNueva,
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
          ? _estadoPedir(
              mensaje:
                  'Demasiados intentos. Espera ${restante.inSeconds} segundos.',
              bloqueo: restante,
            )
          : _estadoPedir();
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
