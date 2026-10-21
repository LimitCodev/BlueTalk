import 'package:flutter/services.dart';

/// Estado real de la protección contra desinstalación.
///
/// `activo == true` significa que Android ya tiene a BlueTalk como
/// administrador del dispositivo: desinstalarla desde Ajustes exige antes
/// pasar por la pantalla de desactivación.
class ProteccionEstado {
  const ProteccionEstado({this.activo = false});

  final bool activo;

  static const inactiva = ProteccionEstado();
}

/// Acceso a la protección contra desinstalación (administrador de
/// dispositivo).
abstract interface class ProteccionGateway {
  Future<ProteccionEstado> estado();

  /// Abre la pantalla de Android para activarse como administrador.
  Future<bool> pedirActivacion();

  /// Quita la app de administradores. Solo se llama desde el modo padre.
  Future<void> desactivar();
}

/// Implementación real con el canal nativo `bluetalk/proteccion`.
///
/// Si el canal no existe (tests, escritorio), devuelve estados
/// inofensivos y `false`: nunca se finge que la protección está puesta.
class PlatformProteccionGateway implements ProteccionGateway {
  const PlatformProteccionGateway();

  static const _canal = MethodChannel('bluetalk/proteccion');

  @override
  Future<ProteccionEstado> estado() async {
    try {
      final mapa = await _canal.invokeMethod<Map<Object?, Object?>>('activo');
      if (mapa == null) return ProteccionEstado.inactiva;
      return ProteccionEstado(activo: mapa['activo'] == true);
    } on MissingPluginException {
      return ProteccionEstado.inactiva;
    } on PlatformException {
      return ProteccionEstado.inactiva;
    }
  }

  @override
  Future<bool> pedirActivacion() async {
    try {
      return await _canal.invokeMethod<bool>('pedirActivacion') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> desactivar() async {
    try {
      await _canal.invokeMethod<void>('desactivar');
    } on MissingPluginException {
      // Sin canal (tests/escritorio) no hay administrador que quitar.
    } on PlatformException {
      // Nada que hacer: el estado se vuelve a leer después.
    }
  }
}
