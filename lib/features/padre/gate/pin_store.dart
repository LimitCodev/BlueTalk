import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultado de verificar el PIN en el gate.
enum VerificacionPin { correcto, incorrecto, bloqueado }

/// Almacenamiento seguro del PIN de la zona de adultos (plan 05 §1).
///
/// El PIN **nunca** se guarda: solo su huella PBKDF2-HMAC-SHA256 (librería
/// `cryptography`) con una sal aleatoria de 16 bytes por PIN. Los intentos
/// fallidos y el instante en que termina el bloqueo también se persisten,
/// para que el lockout sobreviva a un reinicio del teléfono.
///
/// Regla: 5 intentos fallidos → 60 s de espera. Mientras dura el bloqueo
/// `verificar` devuelve [VerificacionPin.bloqueado] y no consume intentos.
class PinStore {
  PinStore(this._prefs, {required this.ahora});

  static const claveHash = 'padre_pin_hash';
  static const claveSalt = 'padre_pin_salt';
  static const claveIntentos = 'padre_pin_intentos';
  static const claveBloqueo = 'padre_pin_bloqueo_hasta';

  /// Intentos fallidos permitidos antes del bloqueo.
  static const intentosMaximos = 5;

  /// Espera impuesta tras agotar los intentos.
  static const esperaDeBloqueo = Duration(seconds: 60);

  /// Iteraciones de PBKDF2: 10.000 ≈ 130 ms en un dispositivo modesto.
  /// La fuerza real del PIN viene de la sal y del lockout, no de repetir
  /// iteraciones hasta congelar la app en gama baja.
  static const _iteraciones = 10000;

  static final Pbkdf2 _algoritmo = Pbkdf2.hmacSha256(
    iterations: _iteraciones,
    bits: 256,
  );

  static final Random _aleatorio = Random.secure();
  static final RegExp _formatoPin = RegExp(r'^\d{4}$');

  final SharedPreferences _prefs;

  /// Reloj inyectable: el bloqueo se calcula contra este reloj.
  final DateTime Function() ahora;

  /// ¿Ya existe un PIN guardado (huella + sal)?
  bool get creado =>
      _prefs.containsKey(claveHash) && _prefs.containsKey(claveSalt);

  /// Intentos fallidos acumulados en este ciclo (persistidos).
  int get intentosFallidos => _prefs.getInt(claveIntentos) ?? 0;

  /// Tiempo que queda de bloqueo; [Duration.zero] si no hay bloqueo.
  Duration bloqueoRestante() {
    final hasta = _prefs.getInt(claveBloqueo);
    if (hasta == null) return Duration.zero;
    final restante =
        DateTime.fromMillisecondsSinceEpoch(hasta).difference(ahora());
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Guarda la huella de un PIN nuevo y limpia el estado del lockout.
  Future<void> crear(String pin) async {
    if (!_formatoPin.hasMatch(pin)) {
      throw const FormatException('El código debe tener 4 dígitos.');
    }
    final salt = [for (var i = 0; i < 16; i++) _aleatorio.nextInt(256)];
    final hash = await _derivar(pin, salt);
    await _prefs.setString(claveSalt, _aHex(salt));
    await _prefs.setString(claveHash, _aHex(hash));
    await _prefs.remove(claveIntentos);
    await _prefs.remove(claveBloqueo);
  }

  /// Comprueba el PIN. No guarda ni registra el valor en claro en ningún
  /// sitio; solo incrementa contadores.
  Future<VerificacionPin> verificar(String pin) async {
    if (bloqueoRestante() > Duration.zero) return VerificacionPin.bloqueado;
    if (!creado || !_formatoPin.hasMatch(pin)) {
      return VerificacionPin.incorrecto;
    }

    final List<int> guardado;
    final List<int> salt;
    try {
      guardado = _deHex(_prefs.getString(claveHash)!);
      salt = _deHex(_prefs.getString(claveSalt)!);
    } on FormatException {
      // Almacenamiento corrupto: se trata como código incorrecto.
      return VerificacionPin.incorrecto;
    }

    final hash = await _derivar(pin, salt);
    if (_esIgual(hash, guardado)) {
      await _prefs.remove(claveIntentos);
      return VerificacionPin.correcto;
    }

    final intentos = intentosFallidos + 1;
    if (intentos >= intentosMaximos) {
      await _prefs.setInt(
        claveBloqueo,
        ahora().add(esperaDeBloqueo).millisecondsSinceEpoch,
      );
      // El contador se reinicia: cuando pase la espera vuelve a haber
      // 5 intentos. Si no se reiniciara, un solo fallo re-bloquearía.
      await _prefs.setInt(claveIntentos, 0);
    } else {
      await _prefs.setInt(claveIntentos, intentos);
    }
    return VerificacionPin.incorrecto;
  }

  Future<List<int>> _derivar(String pin, List<int> salt) async {
    final clave = await _algoritmo.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return clave.extractBytes();
  }

  /// Comparación en tiempo constante de las huellas.
  static bool _esIgual(List<int> a, List<int> b) {
    var diferencia = a.length ^ b.length;
    for (var i = 0; i < a.length && i < b.length; i++) {
      diferencia |= a[i] ^ b[i];
    }
    return diferencia == 0;
  }

  static String _aHex(List<int> bytes) => [
        for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
      ].join();

  static List<int> _deHex(String hex) {
    if (hex.length.isOdd || hex.length < 2) {
      throw const FormatException('Huella corrupta.');
    }
    final salida = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      final par = hex.substring(i, i + 2);
      final valor = int.tryParse(par, radix: 16);
      if (valor == null) throw const FormatException('Huella corrupta.');
      salida.add(valor);
    }
    return salida;
  }
}
