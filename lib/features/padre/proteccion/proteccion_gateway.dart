import '../../../core/plataforma/canal_nativo.dart';

/// Estado real de la protección contra desinstalación.
///
/// `activo == true` significa que Android ya tiene a BlueTalk como
/// administrador del dispositivo: desinstalarla desde Ajustes exige antes
/// pasar por la pantalla de desactivación.
class ProteccionEstado {
  const ProteccionEstado({this.activo = false, this.comprobado = true});

  final bool activo;

  /// `false` cuando el canal nativo no contestó y el estado anterior no
  /// significa nada: no se puede decir ni «activo» ni «falta concederlo».
  final bool comprobado;

  static const inactiva = ProteccionEstado();

  /// Canal caído o sin contestar: nada de lo de arriba es cierto.
  static const sinComprobar = ProteccionEstado(comprobado: false);
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

  static const _canal = CanalNativo('bluetalk/proteccion');

  @override
  Future<ProteccionEstado> estado() async {
    final mapa = await _canal.mapa('activo');
    if (mapa == null) return ProteccionEstado.sinComprobar;
    return ProteccionEstado(activo: mapa['activo'] == true);
  }

  @override
  Future<bool> pedirActivacion() => _canal.orden('pedirActivacion');

  /// Sin canal no hay administrador que quitar; el estado se relee después.
  @override
  Future<void> desactivar() => _canal.pedir<void>('desactivar');
}
