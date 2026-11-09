import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:bluetalk/core/almacen/almacen_local.dart';

import 'almacen_pin.dart';

/// Resultado de verificar el PIN en el gate.
enum VerificacionPin { correcto, incorrecto, bloqueado }

/// Deriva la huella PBKDF2 del PIN.
///
/// Interfaz estrecha para poder sustituirla en tests de widget: `Isolate.run`
/// no completa dentro de `testWidgets` (FakeAsync no procesa mensajes de
/// isolates; ver `docs/plan/12-modo-nino-kiosko-y-panel.md` §0.2) y la PBKDF2
/// en la zona actual solo avanza con pumps. Los tests de unidad sí usan la
/// implementación real.
abstract class DerivadorPin {
  Future<List<int>> derivar(String pin, List<int> salt, int iteraciones);
}

/// PBKDF2-HMAC-SHA256 en un isolate: la UI no se congela mientras se deriva
/// la clave (plan 11 §1.2, estándar 0.1.8).
class DerivadorPinAislamiento implements DerivadorPin {
  const DerivadorPinAislamiento();

  @override
  Future<List<int>> derivar(String pin, List<int> salt, int iteraciones) {
    return Isolate.run(() async {
      final algoritmo = Pbkdf2.hmacSha256(iterations: iteraciones, bits: 256);
      final clave = await algoritmo.deriveKeyFromPassword(
        password: pin,
        nonce: salt,
      );
      return clave.extractBytes();
    });
  }
}

/// Almacenamiento seguro del PIN de la zona de adultos (plan 05 §1,
/// endurecido en plan 11 §1.2).
///
/// El PIN **nunca** se guarda: solo su huella PBKDF2-HMAC-SHA256 (librería
/// `cryptography`) con una sal aleatoria de 16 bytes por PIN, y esa huella
/// y su sal viven en el almacén cifrado del sistema [AlmacenPin], no en
/// preferencias en claro. Junto a la
/// huella se persisten los parámetros con los que se derivó
/// ([claveLongitud] y [claveIteraciones]): los PIN creados antes de esta
/// versión (4 dígitos, 10 000 iteraciones sin registrar) **siguen
/// funcionando**, y en cuanto se autentican correctamente se re-hashean con
/// los parámetros actuales. No se guarda nada en claro.
///
/// Bloqueo escalonado (plan 11 §1.2): 5 intentos fallidos → 60 s; cada ciclo
/// de fallos posterior espera más ([esperasEscalonadas], tope 900 s). El
/// nivel persiste y se resetea al acertar. Se guardan tanto el instante en
/// que empieza el bloqueo ([claveBloqueoDesde]) como el en que termina
/// ([claveBloqueo]): si el reloj del dispositivo se atrasa, el bloqueo se
/// mantiene con su espera original y no se acorta.
class PinStore {
  PinStore(
    this._prefs, {
    required this.almacen,
    required this.ahora,
    this.derivador = const DerivadorPinAislamiento(),
  });

  /// Almacén cifrado de huellas y sales (encargo 3.1): ahí vive el secreto,
  /// nunca en `SharedPreferences`. Ver [AlmacenPin].
  final AlmacenPin almacen;

  static const claveHash = 'padre_pin_hash';
  static const claveSalt = 'padre_pin_salt';
  static const claveIntentos = 'padre_pin_intentos';
  static const claveBloqueo = 'padre_pin_bloqueo_hasta';
  static const claveBloqueoDesde = 'padre_pin_bloqueo_desde';
  static const claveNivel = 'padre_pin_nivel';
  static const claveLongitud = 'padre_pin_len';
  static const claveIteraciones = 'padre_pin_iter';

  // Código de recuperación (solicitud del dueño, 2026-10-19): como el PIN,
  // solo se guarda su huella PBKDF2; el código en claro se muestra una vez.
  static const claveRecupHash = 'padre_recup_hash';
  static const claveRecupSalt = 'padre_recup_salt';
  static const claveRecupIter = 'padre_recup_iter';

  /// Alfabeto del código de recuperación: 32 caracteres sin la letra I ni
  /// la O ni el 0 ni el 1 (evita el error de leer o teclear un carácter
  /// ambiguo).
  static const alfabetoRecuperacion = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Caracteres del código de recuperación (sin el guion que lo parte en dos
  /// grupos de 4 al mostrarse: `XXXX-XXXX`).
  static const longitudRecuperacion = 8;

  /// Intentos fallidos permitidos antes del bloqueo.
  static const intentosMaximos = 5;

  /// Dígitos de todo PIN creado desde esta versión (plan 11 §1.2).
  static const longitudNueva = 6;

  /// Los PIN creados antes de esta versión tienen 4 dígitos: si
  /// [claveLongitud] no existe, se asume 4 (migración sin pérdida de
  /// acceso).
  static const longitudAntigua = 4;

  /// Espera del primer bloqueo (5 fallos).
  static const esperaDeBloqueo = Duration(seconds: 60);

  /// Esperas del bloqueo escalonado por nivel, en orden: 60, 120, 300 y
  /// 900 segundos. Cualquier nivel por encima del último usa el tope de
  /// 900 s. Es la secuencia literal del plan 11 §1.2.
  static const esperasEscalonadas = [
    Duration(seconds: 60),
    Duration(seconds: 120),
    Duration(seconds: 300),
    Duration(seconds: 900),
  ];

  /// Iteraciones con las que está hasheado un PIN guardado antes de esta
  /// versión: el esquema antiguo no las registraba.
  static const iteracionesAntiguas = 10000;

  /// Iteraciones efectivas hoy.
  ///
  /// Medido en el AVD de gama baja (API 28, perfil/AOT): 10.000 = 58 ms,
  /// 50.000 = 301 ms y 100.000 = 586 ms por intento. El plan 11 §1.2
  /// permite subir a 100.000 **solo** si mide ≤ 500 ms; no llega (586 ms),
  /// así que se fija el máximo que sí cumple: 50.000, con margen. La
  /// fuerza real del PIN sigue viniendo de la sal, del bloqueo escalonado
  /// y de que solo se guarda la huella. El mecanismo ya está listo:
  /// basta cambiar este valor, porque cada PIN
  /// se re-hashea con los parámetros actuales tras su siguiente acceso
  /// correcto (su hash guardado manda hasta entonces, ver
  /// [_accesoCorrecto]).
  static const iteracionesActuales = 50000;

  static final Random _aleatorio = Random.secure();

  final AlmacenLocal _prefs;

  /// Reloj inyectable: el bloqueo se calcula contra este reloj.
  final DateTime Function() ahora;

  /// Derivación de la huella (isolate en producción, zona actual en tests).
  final DerivadorPin derivador;

  /// ¿Ya existe un PIN guardado (huella + sal)?
  bool get creado => almacen.tiene(claveHash) && almacen.tiene(claveSalt);

  /// ¿Ya existe un código de recuperación guardado (huella + sal)?
  bool get tieneRecuperacion =>
      almacen.tiene(claveRecupHash) && almacen.tiene(claveRecupSalt);

  /// Intentos fallidos acumulados en este ciclo (persistidos).
  int get intentosFallidos => _prefs.entero(claveIntentos) ?? 0;

  /// Nivel actual del bloqueo escalonado (0 = sin bloqueos todavía).
  int get nivelBloqueo => _prefs.entero(claveNivel) ?? 0;

  /// Longitud del PIN guardado para la interfaz: 4 si el PIN es de una
  /// versión anterior; un valor persistido corrupto se muestra como 6
  /// (igual no dejará pasar a nadie: [verificar] lo rechaza).
  int get longitudGuardada {
    final guardado = _prefs.entero(claveLongitud);
    if (guardado == null) return longitudAntigua;
    if (guardado == longitudAntigua || guardado == longitudNueva) {
      return guardado;
    }
    return longitudNueva;
  }

  /// Iteraciones con las que está hasheado el PIN guardado. Ausente = 10.000
  /// (esquema antiguo, plan 11 §1.2).
  int get iteracionesGuardadas =>
      _prefs.entero(claveIteraciones) ?? iteracionesAntiguas;

  /// Espera que impone el bloqueo de un ciclo concreto.
  static Duration esperaDelNivel(int nivel) {
    if (nivel <= 1) return esperasEscalonadas.first;
    final indice = min(nivel - 1, esperasEscalonadas.length - 1);
    return esperasEscalonadas[indice];
  }

  /// Tiempo que queda de bloqueo; [Duration.zero] si no hay bloqueo.
  ///
  /// Si el reloj del dispositivo está atrasado respecto al instante en que
  /// empezó el bloqueo ([claveBloqueoDesde]), se devuelve la espera
  /// completa original: atrasar el reloj no acorta ni suspende el bloqueo
  /// (plan 11 §1.2).
  Duration bloqueoRestante() {
    final hasta = _prefs.entero(claveBloqueo);
    if (hasta == null) return Duration.zero;
    final instante = DateTime.fromMillisecondsSinceEpoch(hasta);

    final desde = _prefs.entero(claveBloqueoDesde);
    if (desde != null) {
      final inicio = DateTime.fromMillisecondsSinceEpoch(desde);
      if (ahora().isBefore(inicio)) {
        return instante.difference(inicio);
      }
    }

    final restante = instante.difference(ahora());
    return restante.isNegative ? Duration.zero : restante;
  }

  /// Guarda la huella de un PIN nuevo (siempre de 6 dígitos) y limpia el
  /// estado del lockout.
  Future<void> crear(String pin) async {
    if (!_esFormato(pin, longitudNueva)) {
      throw const FormatException('El código debe tener 6 dígitos.');
    }
    await _guardarHuella(pin, longitud: longitudNueva);
    await _limpiarLockout();
  }

  /// Genera un código de recuperación nuevo y lo devuelve en claro **una
  /// sola vez** (formato `XXXX-XXXX`): solo se persiste su huella PBKDF2,
  /// igual que el PIN. Si ya existía, este lo invalida.
  Future<String> generarRecuperacion() async {
    final salt = [for (var i = 0; i < 16; i++) _aleatorio.nextInt(256)];
    final codigo = [
      for (var i = 0; i < longitudRecuperacion; i++)
        alfabetoRecuperacion[_aleatorio.nextInt(alfabetoRecuperacion.length)],
    ].join();
    final hash = await derivador.derivar(codigo, salt, iteracionesActuales);
    await almacen.guardar(claveRecupSalt, _aHex(salt));
    await almacen.guardar(claveRecupHash, _aHex(hash));
    await _prefs.guardarEntero(claveRecupIter, iteracionesActuales);
    return '${codigo.substring(0, 4)}-${codigo.substring(4)}';
  }

  /// Comprueba el código de recuperación con el mismo bloqueo escalonado que
  /// el PIN (comparten contadores: el quinto fallo de cualquiera de los dos
  /// bloquea). Un formato inválido no cuenta como intento, igual que el PIN.
  Future<VerificacionPin> verificarRecuperacion(String tecleado) async {
    if (bloqueoRestante() > Duration.zero) return VerificacionPin.bloqueado;
    if (!tieneRecuperacion) return VerificacionPin.incorrecto;

    // Mayúsculas y sin guiones ni espacios: se teclea como se ve (XXXX-XXXX).
    final codigo =
        tecleado.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final valido = codigo.length == longitudRecuperacion &&
        codigo.split('').every(alfabetoRecuperacion.contains);
    if (!valido) return VerificacionPin.incorrecto;

    final List<int> guardado;
    final List<int> salt;
    final int iteraciones;
    try {
      final hashGuardado = almacen.leer(claveRecupHash);
      final salGuardada = almacen.leer(claveRecupSalt);
      if (hashGuardado == null || salGuardada == null) {
        return VerificacionPin.incorrecto;
      }
      guardado = _deHex(hashGuardado);
      salt = _deHex(salGuardada);
      final leidas = _prefs.entero(claveRecupIter) ?? iteracionesActuales;
      if (leidas < 1 || leidas > 1000000) {
        return VerificacionPin.incorrecto;
      }
      iteraciones = leidas;
    } on FormatException {
      return VerificacionPin.incorrecto;
    } on TypeError {
      return VerificacionPin.incorrecto;
    }

    final hash = await derivador.derivar(codigo, salt, iteraciones);
    if (_esIgual(hash, guardado)) {
      await _limpiarLockout();
      return VerificacionPin.correcto;
    }
    await _registrarFallo();
    return VerificacionPin.incorrecto;
  }

  /// Borra **solo** el PIN (huella, sal, parámetros y bloqueo). El resto de
  /// datos del dispositivo se conserva — progreso, horario, ajustes,
  /// consentimientos — y también el código de recuperación, que sigue
  /// valiendo hasta que se regenere. Es la salida no destructiva para un
  /// PIN olvidado (frente al borrado total con la palabra BORRAR).
  ///
  /// Devuelve `false` si alguna huella no se pudo borrar en el keystore:
  /// en ese caso no se toca nada más y quien llama avisa, en vez de fingir
  /// un PIN borrado que seguiría valiendo.
  Future<bool> borrarSoloPin() async {
    final hash = await almacen.borrar(claveHash);
    final sal = await almacen.borrar(claveSalt);
    if (!hash || !sal) return false;
    await _prefs.borrar(claveLongitud);
    await _prefs.borrar(claveIteraciones);
    await _limpiarLockout();
    return true;
  }

  /// Comprueba el PIN. No guarda ni registra el valor en claro en ningún
  /// sitio; solo incrementa contadores y, tras un acceso correcto, migra la
  /// huella si estaba con parámetros antiguos.
  Future<VerificacionPin> verificar(String pin) async {
    if (bloqueoRestante() > Duration.zero) return VerificacionPin.bloqueado;
    if (!creado) return VerificacionPin.incorrecto;

    // Longitud almacenada: 4 para los PIN antiguos. Un valor corrupto no
    // admite ningún código.
    final longitudCruda = _prefs.entero(claveLongitud);
    final longitud = longitudCruda ?? longitudAntigua;
    if (longitud != longitudAntigua && longitud != longitudNueva) {
      return VerificacionPin.incorrecto;
    }
    if (!_esFormato(pin, longitud)) return VerificacionPin.incorrecto;

    // Iteraciones almacenadas: fuera de un rango creíble, almacenamiento
    // corrupto (además, con un valor enorme alguien podría congelar la app
    // pidiendo derivar).
    final iteraciones = iteracionesGuardadas;
    if (iteraciones < 1 || iteraciones > 1000000) {
      return VerificacionPin.incorrecto;
    }

    final List<int> guardado;
    final List<int> salt;
    try {
      final hashGuardado = almacen.leer(claveHash);
      final salGuardada = almacen.leer(claveSalt);
      // Clave ausente o con un tipo que no es texto (almacenamiento
      // corrupto): se trata como código incorrecto, igual que el resto.
      if (hashGuardado == null || salGuardada == null) {
        return VerificacionPin.incorrecto;
      }
      guardado = _deHex(hashGuardado);
      salt = _deHex(salGuardada);
    } on FormatException {
      // Almacenamiento corrupto: se trata como código incorrecto.
      return VerificacionPin.incorrecto;
    } on TypeError {
      // Tipo inesperado bajo la clave: misma respuesta.
      return VerificacionPin.incorrecto;
    }

    final hash = await derivador.derivar(pin, salt, iteraciones);
    if (_esIgual(hash, guardado)) {
      await _accesoCorrecto(
        pin,
        longitud: longitud,
        iteracionesLeidas: iteraciones,
      );
      return VerificacionPin.correcto;
    }

    await _registrarFallo();
    return VerificacionPin.incorrecto;
  }

  /// Acceso correcto: limpia el lockout, fija la longitud persistida y
  /// re-hashea con los parámetros actuales si la huella estaba guardada con
  /// un esquema antiguo (plan 11 §1.2).
  ///
  /// El re-hasheo usa una sal nueva y el PIN en claro que la persona acaba
  /// de escribir; hasta ese momento su hash antiguo sigue mandando, así que
  /// un PIN de 4 dígitos no pierde el acceso.
  Future<void> _accesoCorrecto(
    String pin, {
    required int longitud,
    required int iteracionesLeidas,
  }) async {
    await _limpiarLockout();
    // Migración de longitud: los PIN antiguos siguen pidiendo sus 4
    // dígitos; ahora queda registrado junto a la huella.
    await _prefs.guardarEntero(claveLongitud, longitud);

    final esquemaAntiguo = !_prefs.contiene(claveIteraciones) ||
        iteracionesLeidas != iteracionesActuales;
    if (!esquemaAntiguo) return;
    await _guardarHuella(pin, longitud: longitud);
  }

  /// Registra un intento fallido; el quinto y los siguientes ciclos suben el
  /// nivel del bloqueo escalonado (60, 120, 300 y 900 s, tope 900 s).
  Future<void> _registrarFallo() async {
    final intentos = intentosFallidos + 1;
    if (intentos < intentosMaximos) {
      await _prefs.guardarEntero(claveIntentos, intentos);
      return;
    }

    final nivel = nivelBloqueo + 1;
    final desde = ahora();
    await _prefs.guardarEntero(claveNivel, nivel);
    await _prefs.guardarEntero(claveBloqueoDesde, desde.millisecondsSinceEpoch);
    await _prefs.guardarEntero(
      claveBloqueo,
      desde.add(esperaDelNivel(nivel)).millisecondsSinceEpoch,
    );
    // El contador se reinicia: cuando pase la espera vuelve a haber
    // 5 intentos. Si no se reiniciara, un solo fallo re-bloquearía.
    await _prefs.guardarEntero(claveIntentos, 0);
  }

  /// Deriva y persiste la huella de [pin] con los parámetros actuales y la
  /// [longitud] del código que se acaba de validar (4 en la migración de un
  /// PIN antiguo: no se le cambian los dígitos).
  Future<void> _guardarHuella(String pin, {required int longitud}) async {
    final salt = [for (var i = 0; i < 16; i++) _aleatorio.nextInt(256)];
    final hash = await derivador.derivar(pin, salt, iteracionesActuales);
    await almacen.guardar(claveSalt, _aHex(salt));
    await almacen.guardar(claveHash, _aHex(hash));
    await _prefs.guardarEntero(claveLongitud, longitud);
    await _prefs.guardarEntero(claveIteraciones, iteracionesActuales);
  }

  Future<void> _limpiarLockout() async {
    await _prefs.borrar(claveIntentos);
    await _prefs.borrar(claveBloqueo);
    await _prefs.borrar(claveBloqueoDesde);
    await _prefs.borrar(claveNivel);
  }

  static bool _esFormato(String pin, int longitud) =>
      RegExp('^[0-9]{$longitud}\$').hasMatch(pin);

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
