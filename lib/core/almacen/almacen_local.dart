import 'package:shared_preferences/shared_preferences.dart';

/// Única puerta de la app al almacenamiento clave-valor del dispositivo.
///
/// Las pantallas, controladores y repositorios piden aquí; ninguno toca
/// `SharedPreferences` por su cuenta (lo vigila
/// `test/arquitectura/capas_test.dart`). Así el soporte se puede cambiar
/// (cifrado, base de datos, copia de seguridad) en un solo sitio.
///
/// Cada feature sigue siendo dueña de sus claves: las declara junto al
/// código que las usa y no cambian de nombre (son datos ya guardados en
/// teléfonos reales).
abstract interface class AlmacenLocal {
  String? texto(String clave);
  bool? booleano(String clave);
  int? entero(String clave);
  List<String>? lista(String clave);
  bool contiene(String clave);

  Future<void> guardarTexto(String clave, String valor);
  Future<void> guardarBooleano(String clave, bool valor);
  Future<void> guardarEntero(String clave, int valor);
  Future<void> guardarLista(String clave, List<String> valor);

  Future<void> borrar(String clave);

  /// Borra todo lo guardado con esta puerta. No toca el keystore.
  Future<void> borrarTodo();
}

/// Implementación sobre `SharedPreferences` (almacenamiento privado).
class AlmacenPrefs implements AlmacenLocal {
  const AlmacenPrefs(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? texto(String clave) => _prefs.getString(clave);

  @override
  bool? booleano(String clave) => _prefs.getBool(clave);

  @override
  int? entero(String clave) => _prefs.getInt(clave);

  @override
  List<String>? lista(String clave) => _prefs.getStringList(clave);

  @override
  bool contiene(String clave) => _prefs.containsKey(clave);

  @override
  Future<void> guardarTexto(String clave, String valor) =>
      _prefs.setString(clave, valor);

  @override
  Future<void> guardarBooleano(String clave, bool valor) =>
      _prefs.setBool(clave, valor);

  @override
  Future<void> guardarEntero(String clave, int valor) =>
      _prefs.setInt(clave, valor);

  @override
  Future<void> guardarLista(String clave, List<String> valor) =>
      _prefs.setStringList(clave, valor);

  @override
  Future<void> borrar(String clave) => _prefs.remove(clave);

  @override
  Future<void> borrarTodo() => _prefs.clear();
}
