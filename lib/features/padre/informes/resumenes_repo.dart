import 'dart:convert';

import '../../../core/almacen/almacen_local.dart';
import '../../../data/models/models.dart';
import 'acumular_evento.dart';
import 'dia.dart';
import 'resumen_dia.dart';

/// Resúmenes diarios por mes; `sumar` agrupa escrituras (PERF-CORE-01).
class ResumenesRepo {
  ResumenesRepo(this._almacen);

  static const mesesGuardados = 13;
  static const _indice = 'bluetalk_resumen_meses';
  static const _sembrado = 'bluetalk_resumen_sembrado';
  static const _lote = 100;

  final AlmacenLocal _almacen;
  final _cache = <String, Map<String, ResumenDia>>{};
  final _pendientes = <String>{};
  var _eventosPendientes = 0;

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

  bool get sembrado => _almacen.booleano(_sembrado) ?? false;

  Future<void> marcarSembrado() => _almacen.guardarBooleano(_sembrado, true);

  List<ResumenDia> rango(DateTime desde, DateTime hasta) => [
    for (final f in diasHasta(hasta, hasta.difference(desde).inDays + 1))
      ?dia(claveDia(f)),
  ];

  Future<void> sumar(UsageEvent e) async {
    final r = acumular(dia(claveDia(e.createdAt)), e);
    final mes = r.dia.substring(0, 7);
    _mes(mes)[r.dia] = r;
    _pendientes.add(mes);
    if (++_eventosPendientes >= _lote) await flush();
  }

  Future<void> flush() async {
    if (_pendientes.isEmpty) return;
    final meses = [..._pendientes];
    _pendientes.clear();
    _eventosPendientes = 0;
    for (final mes in meses) {
      await _escribirMes(mes);
    }
    await _guardarIndice(meses);
  }

  Future<void> guardar(ResumenDia r) async {
    final mes = r.dia.substring(0, 7);
    _mes(mes)[r.dia] = r;
    await _escribirMes(mes);
    await _guardarIndice([mes]);
  }

  Future<void> _escribirMes(String mes) => _almacen.guardarTexto(
    'bluetalk_resumen_$mes',
    jsonEncode({for (final e in _mes(mes).entries) e.key: e.value.toMap()}),
  );

  Future<void> _guardarIndice(List<String> meses) async {
    final previo = _almacen.lista(_indice) ?? const [];
    final nuevos = [
      for (final m in meses)
        if (!previo.contains(m)) m,
    ];
    if (nuevos.isEmpty) return;
    final indice = [...previo, ...nuevos]..sort();
    while (indice.length > mesesGuardados) {
      final viejo = indice.removeAt(0);
      _cache.remove(viejo);
      await _almacen.borrar('bluetalk_resumen_$viejo');
    }
    await _almacen.guardarLista(_indice, indice);
  }
}
