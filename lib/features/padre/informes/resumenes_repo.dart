import 'dart:convert';

import '../../../core/almacen/almacen_local.dart';
import '../../../data/models/models.dart';
import 'acumular_evento.dart';
import 'dia.dart';
import 'resumen_dia.dart';

/// Resúmenes diarios guardados por mes: una clave por mes
/// (`bluetalk_resumen_AAAA-MM`). Así cada toque reescribe ~31 días y no
/// el año entero, y se conservan [mesesGuardados] meses.
class ResumenesRepo {
  ResumenesRepo(this._almacen);

  static const mesesGuardados = 13;
  static const _indice = 'bluetalk_resumen_meses';
  static const _sembrado = 'bluetalk_resumen_sembrado';

  final AlmacenLocal _almacen;
  final _cache = <String, Map<String, ResumenDia>>{};

  Map<String, ResumenDia> _mes(String mes) => _cache.putIfAbsent(mes, () {
        final crudo = _almacen.texto('bluetalk_resumen_$mes');
        if (crudo == null) return {};
        try {
          final m = jsonDecode(crudo) as Map<String, dynamic>;
          return {
            for (final e in m.entries)
              e.key: ResumenDia.fromMap(Map<String, dynamic>.from(e.value as Map)),
          };
        } on Object {
          return {}; // Mes corrupto: se empieza de cero, no se rompe.
        }
      });

  ResumenDia? dia(String clave) => _mes(clave.substring(0, 7))[clave];

  /// Días con datos entre [desde] y [hasta] (incluidos), en orden.
  List<ResumenDia> rango(DateTime desde, DateTime hasta) {
    final dias = hasta.difference(desde).inDays + 1;
    return [
      for (final f in diasHasta(hasta, dias))
        ?dia(claveDia(f)),
    ];
  }

  /// Lectura y suma sin `await` en medio: dos eventos seguidos no se pisan.
  Future<void> sumar(UsageEvent e) => guardar(acumular(dia(claveDia(e.createdAt)), e));

  Future<void> guardar(ResumenDia r) async {
    final mes = r.dia.substring(0, 7);
    final dias = _mes(mes)..[r.dia] = r;
    final indice = {...?_almacen.lista(_indice), mes}.toList()..sort();
    await _almacen.guardarTexto('bluetalk_resumen_$mes',
        jsonEncode({for (final e in dias.entries) e.key: e.value.toMap()}));
    while (indice.length > mesesGuardados) {
      final viejo = indice.removeAt(0);
      _cache.remove(viejo);
      await _almacen.borrar('bluetalk_resumen_$viejo');
    }
    await _almacen.guardarLista(_indice, indice);
  }

  /// Primera vez: rellena con los eventos sueltos que ya había (14 días).
  /// Solo días sin resumen, para no contar dos veces el de hoy.
  Future<void> sembrarUnaVez(List<UsageEvent> eventos) async {
    if (_almacen.booleano(_sembrado) ?? false) return;
    final nuevos = <String, ResumenDia>{};
    for (final e in eventos) {
      final clave = claveDia(e.createdAt);
      if (dia(clave) != null) continue;
      nuevos[clave] = acumular(nuevos[clave], e);
    }
    for (final r in nuevos.values) {
      await guardar(r);
    }
    await _almacen.guardarBooleano(_sembrado, true);
  }
}
