import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bluetalk/core/almacen/almacen_local.dart';

/// Almacenamiento de las **huellas** del PIN (encargo §3.1).
///
/// El PIN en claro nunca se guarda en ningún sitio: se deriva con
/// PBKDF2-HMAC-SHA256 y solo se persiste la huella, con su sal. Esta clase
/// decide **dónde** vive esa huella:
///
/// 1. En el almacén cifrado del sistema (`flutter_secure_storage`, keystore
///    de Android) cuando está operativo — es el caso de producción y el
///    que pide el encargo.
/// 2. En `SharedPreferences` **solo** como respaldo cuando el sistema no
///    puede cifrar. Nunca es un camino silencioso: [cifrado] lo cuenta y la
///    pantalla de estado del modo padre lo enseña.
///
/// Se sirve de caché en memoria ([leer] y [tener] son síncronos) porque el
/// gate consulta el PIN al construir su UI. El precargado lo hace `main()`
/// con [cargar], que además **migra** las huellas que estuvieran todavía en
/// `SharedPreferences` y comprueba con una escritura real antes de tocar
/// nada: si el keystore falla, no se migra y no se pierde acceso al PIN.
class AlmacenPin {
  AlmacenPin({
    required AlmacenLocal prefs,
    FlutterSecureStorage? sistema,
  })  : _preferencias = prefs,
        _sistema = sistema ?? const FlutterSecureStorage();

  final AlmacenLocal _preferencias;
  final FlutterSecureStorage _sistema;

  final Map<String, String> _cache = {};

  bool _cargado = false;

  /// El keystore **contiene** alguna huella secreta (leída en [cargar] o
  /// escrita al migrar), aunque luego no admita escrituras.
  ///
  /// Hace falta para que [borrar] y [borrarSecretas] sepan que tienen que
  /// borrar allí aunque la prueba de escritura fallara: si se fiaran solo
  /// de [_keystoreListo], una huella olvidada en el keystore volvería a
  /// leerse en el próximo arranque.
  bool _huellasEnSistema = false;

  /// El keystore respondió bien en [cargar]: solo entonces se le escribe.
  ///
  /// Así las pruebas (sin canal de plataforma) y un arranque sin precargar
  /// van directo a preferencias sin una llamada de plataforma que retrase
  /// la UI, y un keystore dañado no recibe escrituras a medias.
  bool _keystoreListo = false;

  /// ¿Las huellas viven en el keystore?
  bool _cifrado = false;

  /// `true` cuando las huellas viven cifradas en el keystore del sistema.
  ///
  /// `false` = siguen en preferencias locales porque el keystore no
  /// respondió. Se muestra en pantalla; no es un fallo silencioso.
  bool get cifrado => _cifrado;

  bool get cargado => _cargado;

  /// Claves que deben vivir cifradas: las huellas y sus sales.
  ///
  /// Los parámetros de derivación (`padre_pin_len`, `padre_pin_iter`) y los
  /// contadores de bloqueo **no** son secretos: se quedan donde estaban,
  /// porque moverlos a un almacén asíncrono rompería lecturas síncronas
  /// del gate sin ganar seguridad.
  static const clavesSecretas = <String>[
    'padre_pin_hash',
    'padre_pin_salt',
    'padre_recup_hash',
    'padre_recup_salt',
  ];

  static const _pruebaKeystore = 'bluetalk_prueba_keystore';

  /// Lee el keystore, comprueba que escribe, y si todo va bien mueve hacia
  /// él las huellas que estén en `SharedPreferences` (migración de los PINs
  /// creados antes de esta versión).
  ///
  /// Nunca borra de `SharedPreferences` algo que no haya escrito antes en
  /// el keystore: un fallo a mitad no puede dejar a nadie sin PIN.
  Future<void> cargar() async {
    if (_cargado) return;
    _cargado = true;

    Map<String, String> leidas;
    try {
      leidas = await _sistema.readAll();
    } on MissingPluginException {
      return;
    } on Exception {
      return;
    } on Error {
      return;
    }

    _cache
      ..clear()
      ..addAll(leidas);
    _huellasEnSistema = leidas.keys.any(clavesSecretas.contains);

    // Prueba de escritura real antes de migrar.
    try {
      await _sistema.write(key: _pruebaKeystore, value: '1');
      await _sistema.delete(key: _pruebaKeystore);
      _keystoreListo = true;
      // El keystore acepta escrituras: ahí van las huellas de ahora en
      // adelante, aunque todavía no existan. [cifrado] lo cuenta en
      // pantalla sin esperar a que alguien cree un PIN.
      _cifrado = true;
    } on MissingPluginException {
      // Sin canal: nada que usar. La caché empieza vacía.
      return;
    } on Exception {
      // Keystore que lee pero no escribe: no se manda por él. Dejar aquí
      // lo que devolvió `readAll` haría que una huella guardada después
      // en preferencias se leyera vieja.
      _cache.clear();
      return;
    } on Error {
      _cache.clear();
      return;
    }

    for (final clave in clavesSecretas) {
      if (_cache.containsKey(clave)) continue;
      final antigua = _preferencias.texto(clave);
      if (antigua == null) continue;
      try {
        await _sistema.write(key: clave, value: antigua);
      } on Exception {
        // Alguna huella sigue en texto plano: [cifrado] no puede decir
        // que todo está cifrado.
        _cifrado = false;
        return;
      }
      _cache[clave] = antigua;
      await _preferencias.borrar(clave);
      _cifrado = true;
      _huellasEnSistema = true;
    }

    // Si ya había huellas en el keystore, está cifrado. Si hay alguna en
    // preferencias (migración a medias), no.
    if (_cache.isNotEmpty && _keystoreListo) {
      _cifrado = !clavesSecretas.any(_preferencias.contiene);
    }
  }

  /// Lectura síncrona: caché primero, preferencias después.
  String? leer(String clave) => _cache[clave] ?? _preferencias.texto(clave);

  bool tiene(String clave) => _cache.containsKey(clave) || _preferencias.contiene(clave);

  Future<void> guardar(String clave, String valor) async {
    if (!_keystoreListo) {
      // Keystore sin verificar (tests, o arranque sin precargar): igual
      // que antes de esta versión. [cifrado] lo declara.
      await _soloPrefs(clave, valor);
      return;
    }
    try {
      await _sistema.write(key: clave, value: valor);
      _cache[clave] = valor;
      _cifrado = true;
      // Fuera del archivo en claro en cuanto ya está en el keystore.
      await _preferencias.borrar(clave);
    } on MissingPluginException {
      await _soloPrefs(clave, valor);
    } on Exception {
      await _soloPrefs(clave, valor);
    } on Error {
      await _soloPrefs(clave, valor);
    }
  }

  Future<void> _soloPrefs(String clave, String valor) async {
    _cifrado = false;
    await _preferencias.guardarTexto(clave, valor);
    // La caché se vacía de esa clave: si no, [leer] seguiría devolviendo la
    // huella vieja del keystore y el PIN recién creado no abriría hasta el
    // próximo arranque. La preferencia recién escrita es la que manda.
    _cache.remove(clave);
  }

  /// Borra una clave de donde esté: keystore, preferencias y caché.
  ///
  /// El keystore va **primero**: si ahí no se puede borrar, devuelve
  /// `false` y no se toca nada, porque una huella que sobreviva se vuelve a
  /// leer en el próximo arranque y el código viejo vuelve a valer.
  Future<bool> borrar(String clave) async {
    if (_keystoreListo || _huellasEnSistema) {
      try {
        await _sistema.delete(key: clave);
      } on MissingPluginException {
        // Sin canal (tests, escritorio): nunca llegó a escribirse ahí.
      } on Exception {
        return false;
      } on Error {
        return false;
      }
    }
    _cache.remove(clave);
    await _preferencias.borrar(clave);
    return true;
  }

  /// Borra **todas** las huellas secretas: del keystore, de preferencias y
  /// de la caché.
  ///
  /// Es el cierre que necesita el borrado total de `RecuperarScreen`:
  /// `prefs.clear()` por sí solo no toca el keystore y dejaría la huella del
  /// PIN vivo, con lo que el próximo arranque volvería a pedir el código
  /// que la persona adulta acaba de decir que ha olvidado.
  ///
  /// El keystore va **primero**: si alguna huella no se puede borrar ahí,
  /// devuelve `false` sin tocar preferencias ni caché, para no declarar un
  /// borrado que no ocurrió y dejar los datos sin cambios. Con alguna
  /// huella menos el gate cae en fase «crear» (o en «sin código de
  /// recuperación»), que sí se puede salir; con el PIN viejo a medias no.
  Future<bool> borrarSecretas() async {
    if (_keystoreListo || _huellasEnSistema) {
      for (final clave in clavesSecretas) {
        try {
          await _sistema.delete(key: clave);
        } on MissingPluginException {
          // Nunca llegó a escribirse ahí: no hay nada que borrar.
        } on Exception {
          return false;
        } on Error {
          return false;
        }
      }
    }
    _huellasEnSistema = false;
    for (final clave in clavesSecretas) {
      await _preferencias.borrar(clave);
    }
    _cache.clear();
    return true;
  }
}
