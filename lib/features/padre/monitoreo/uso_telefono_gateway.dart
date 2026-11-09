import '../../../core/plataforma/canal_nativo.dart';

import '../permisos/permiso_model.dart';
import 'uso_telefono_model.dart';

/// Puerta al diagnóstico de uso de Android. En tests se sustituye por un
/// doble; sin canal (escritorio) devuelve «sin permiso» en lugar de romper.
abstract interface class UsoTelefonoGateway {
  Future<bool> estaPermitido();

  /// Igual que [estaPermitido], pero distingue **«no concedido»** de
  /// **«no se pudo comprobar»** (canal nativo caído).
  ///
  /// [permisosProvider] usa este: con un `false` a secas, un fallo de
  /// consulta se convertiría en «falta concederlo» y bloquearía el paso
  /// del modo padre sin que «pedir» pudiera arreglarlo.
  Future<EstadoPermiso> estadoPermiso();

  Future<bool> abrirAjustes();
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta);
}

class PlatformUsoTelefonoGateway implements UsoTelefonoGateway {
  const PlatformUsoTelefonoGateway();

  static const _canal = CanalNativo('bluetalk/uso_telefono');

  @override
  Future<EstadoPermiso> estadoPermiso() async =>
      estadoDesdeBool((await _canal.mapa('estado'))?['permiso']);

  @override
  Future<bool> estaPermitido() async =>
      (await estadoPermiso()) == EstadoPermiso.concedido;

  @override
  Future<bool> abrirAjustes() => _canal.orden('abrirAjustes');

  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async {
    final mapa = await _canal.mapa('resumen', {
      'desde': desde.millisecondsSinceEpoch,
      'hasta': hasta.millisecondsSinceEpoch,
    });
    return mapa == null
        ? ResumenUso.sinPermiso(desde, hasta)
        : ResumenUso.fromMap(mapa);
  }
}
