import 'package:flutter/services.dart';

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

  static const _canal = MethodChannel('bluetalk/uso_telefono');

  @override
  Future<EstadoPermiso> estadoPermiso() async {
    try {
      final mapa = await _canal.invokeMethod<Map<Object?, Object?>>('estado');
      final valor = mapa?['permiso'];
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
  Future<bool> estaPermitido() async =>
      (await estadoPermiso()) == EstadoPermiso.concedido;

  @override
  Future<bool> abrirAjustes() async {
    try {
      return await _canal.invokeMethod<bool>('abrirAjustes') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async {
    try {
      final mapa = await _canal.invokeMethod<Map<Object?, Object?>>(
        'resumen',
        {
          'desde': desde.millisecondsSinceEpoch,
          'hasta': hasta.millisecondsSinceEpoch,
        },
      );
      if (mapa == null) {
        return ResumenUso.sinPermiso(desde, hasta);
      }
      return ResumenUso.fromMap(mapa);
    } on MissingPluginException {
      return ResumenUso.sinPermiso(desde, hasta);
    } on PlatformException {
      return ResumenUso.sinPermiso(desde, hasta);
    }
  }
}
