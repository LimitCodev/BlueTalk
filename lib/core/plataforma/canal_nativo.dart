import 'package:flutter/services.dart';

/// Única puerta de Dart a los canales nativos de Android (`MethodChannel`).
///
/// Los gateways de cada feature piden aquí; ninguno crea su propio
/// `MethodChannel` (lo vigila `test/arquitectura/capas_test.dart`).
///
/// Regla común: si el canal no existe (tests, escritorio) o Android falla,
/// la llamada **no rompe la pantalla** y devuelve `null`. Cada gateway
/// decide qué estado inofensivo enseña con ese `null`; nunca se finge un
/// «concedido» ni un «activo».
class CanalNativo {
  const CanalNativo(this.nombre);

  final String nombre;

  // Objeto ligero (solo guarda el nombre); `const` no aplica en esta versión.
  MethodChannel get _canal => MethodChannel(nombre);

  /// Resultado de [metodo], o `null` si no hubo respuesta válida.
  Future<T?> pedir<T>(String metodo, [Object? argumentos]) async {
    try {
      return await _canal.invokeMethod<T>(metodo, argumentos);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Respuesta en forma de mapa (estados), o `null`.
  Future<Map<Object?, Object?>?> mapa(String metodo, [Object? argumentos]) =>
      pedir<Map<Object?, Object?>>(metodo, argumentos);

  /// Orden que Android confirma con `true`; cualquier otra cosa es `false`.
  Future<bool> orden(String metodo, [Object? argumentos]) async =>
      await pedir<bool>(metodo, argumentos) ?? false;
}
