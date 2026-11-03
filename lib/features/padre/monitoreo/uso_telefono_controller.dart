import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reloj.dart';
import 'uso_telefono_gateway.dart';
import 'uso_telefono_model.dart';

/// Periodo que el adulto quiere revisar.
enum PeriodoUso { hoy, sieteDias }

extension PeriodoUsoTexto on PeriodoUso {
  String get titulo => switch (this) {
        PeriodoUso.hoy => 'Hoy',
        PeriodoUso.sieteDias => 'Últimos 7 días',
      };

  int get dias => switch (this) {
        PeriodoUso.hoy => 1,
        PeriodoUso.sieteDias => 7,
      };
}

class PeriodoUsoController extends Notifier<PeriodoUso> {
  @override
  PeriodoUso build() => PeriodoUso.hoy;

  void set(PeriodoUso periodo) => state = periodo;
}

final periodoUsoProvider =
    NotifierProvider<PeriodoUsoController, PeriodoUso>(
  PeriodoUsoController.new,
);

final usoTelefonoGatewayProvider = Provider<UsoTelefonoGateway>(
  (ref) => const PlatformUsoTelefonoGateway(),
);

/// `true` si Android ya concedió «Acceso al uso» a BlueTalk.
final permisoUsoProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.read(usoTelefonoGatewayProvider).estaPermitido();
});

/// Resumen del periodo elegido. Se recalcula al cambiar de periodo y al
/// volver a la pantalla; no se guarda nada en el teléfono.
final resumenUsoProvider = FutureProvider.autoDispose<ResumenUso>((ref) {
  final periodo = ref.watch(periodoUsoProvider);
  final ahora = ref.watch(relojProvider)();
  final desde = inicioDelDia(ahora)
      .subtract(Duration(days: periodo.dias - 1));
  return ref
      .read(usoTelefonoGatewayProvider)
      .resumen(desde, ahora);
});
