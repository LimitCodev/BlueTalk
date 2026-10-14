import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../app/di.dart';

/// Desbloqueo biométrico opcional del gate (plan 05 §1).
///
/// Interfaz pequeña para poder sustituirlo en tests: `local_auth` habla con
/// un canal de plataforma que no existe dentro de `flutter test`.
abstract interface class Biometria {
  /// ¿El teléfono soporta huella o rostro?
  Future<bool> disponible();

  /// Pide la comprobación al sistema. `false` si el usuario la cancela o
  /// el canal no está disponible.
  Future<bool> autenticar();
}

/// Implementación real con `local_auth` del sistema Android.
class BiometriaDelDispositivo implements Biometria {
  @override
  Future<bool> disponible() async {
    try {
      return await LocalAuthentication().isDeviceSupported();
    } catch (_) {
      // Fuera de un dispositivo real (tests, emulador sin sensores).
      return false;
    }
  }

  @override
  Future<bool> autenticar() async {
    try {
      return await LocalAuthentication().authenticate(
        localizedReason: 'Desbloquea la zona de adultos de BlueTalk',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final biometriaProvider = Provider<Biometria>((ref) => BiometriaDelDispositivo());

/// Interruptor «huella o rostro» del control parental (persistido).
class BiometriaController extends Notifier<bool> {
  static const prefKey = 'padre_biometria';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefKey) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefKey, value);
  }
}

final biometriaHabilitadaProvider = NotifierProvider<BiometriaController, bool>(
  BiometriaController.new,
);
