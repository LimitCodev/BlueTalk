import 'package:bluetalk/features/padre/monitoreo/uso_telefono_gateway.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_model.dart';
import 'package:bluetalk/features/padre/permisos/permiso_model.dart';

/// Doble del canal de uso: 12 apps, 600 s cada día.
class GatewayFalso implements UsoTelefonoGateway {
  GatewayFalso({this.permitido = true});
  final bool permitido;
  final pedidos = <DateTime>[];

  @override
  Future<bool> estaPermitido() async => permitido;
  @override
  Future<EstadoPermiso> estadoPermiso() async =>
      permitido ? EstadoPermiso.concedido : EstadoPermiso.pendiente;
  @override
  Future<bool> abrirAjustes() async => false;
  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async {
    pedidos.add(desde);
    return ResumenUso(
      permiso: true,
      totalSegundos: 600,
      apps: [
        for (var i = 0; i < 12; i++)
          UsoApp(paquete: 'app.$i', nombre: 'App $i', segundos: 600 - i),
      ],
      desde: desde,
      hasta: hasta,
    );
  }
}
