import 'package:flutter/services.dart';

import 'permiso_model.dart';

/// Acceso nativo a los dos permisos que no tienen puente propio:
/// avisos del horario y exclusión de optimización de batería.
///
/// El resto («Acceso al uso», VPN y administrador del dispositivo) ya
/// tienen su gateway y se consultan desde el controlador.
abstract interface class PermisosGateway {
  Future<EstadoPermiso> estadoAvisos();

  Future<EstadoPermiso> estadoBateria();

  /// Pide el permiso de avisos con el diálogo de Android.
  Future<bool> pedirAvisos();

  /// Abre la pantalla de batería de Android.
  Future<bool> pedirBateria();
}

/// Implementación real con el canal nativo `bluetalk/permisos`.
///
/// Sin canal (tests, escritorio) se devuelve [EstadoPermiso.desconocido]
/// en vez de fingir «concedido» o «pendiente»: la pantalla lo enseña como
/// que no se pudo comprobar, y `PermisosEstado.faltanRequeridos` no
/// bloquea con desconocidos.
class PlatformPermisosGateway implements PermisosGateway {
  const PlatformPermisosGateway();

  static const _canal = MethodChannel('bluetalk/permisos');

  @override
  Future<EstadoPermiso> estadoAvisos() => _leer('avisos');

  @override
  Future<EstadoPermiso> estadoBateria() => _leer('bateria');

  Future<EstadoPermiso> _leer(String clave) async {
    try {
      final mapa = await _canal.invokeMethod<Map<Object?, Object?>>('estado');
      final valor = mapa?[clave];
      if (valor is bool) {
        return valor ? EstadoPermiso.concedido : EstadoPermiso.pendiente;
      }
      return EstadoPermiso.desconocido;
    } on MissingPluginException {
      return EstadoPermiso.desconocido;
    } on PlatformException {
      return EstadoPermiso.desconocido;
    }
  }

  @override
  Future<bool> pedirAvisos() => _llamar('pedirAvisos');

  @override
  Future<bool> pedirBateria() => _llamar('pedirBateria');

  Future<bool> _llamar(String metodo) async {
    try {
      return await _canal.invokeMethod<bool>(metodo) ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
