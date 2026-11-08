import '../../../data/models/models.dart';
import 'dia.dart';
import 'informe_modelo.dart';
import 'resumen_dia.dart';

/// Arma el informe que termina en [hasta] con los resúmenes de ese
/// periodo y del anterior. Función pura: no lee ni guarda nada.
Informe construirInforme({
  required Periodo periodo,
  required DateTime hasta,
  required List<ResumenDia> resumenes,
  List<MoodEntry> animos = const [],
  Map<String, String> nombres = const {},
}) {
  final dias = diasHasta(hasta, periodo.dias);
  final previos = diasHasta(dias.first.subtract(const Duration(days: 1)), periodo.dias);
  final porDia = {for (final r in resumenes) r.dia: r};
  final actuales = [for (final d in dias) ?porDia[claveDia(d)]];
  final conApps = actuales.where((r) => r.apps != null).toList();
  String nombre(String id) => nombres[id] ?? id;

  final apps = <String, ({String nombre, int valor})>{};
  for (final r in conApps) {
    for (final e in r.apps!.apps.entries) {
      final previo = apps[e.key]?.valor ?? 0;
      apps[e.key] = (nombre: e.value.nombre, valor: previo + e.value.segundos);
    }
  }
  final enPeriodo = animos.where((m) => !m.date.isBefore(dias.first) &&
      m.date.isBefore(hasta.add(const Duration(days: 1))));

  return Informe(
    periodo: periodo,
    desde: dias.first,
    hasta: dias.last,
    diasConDatos: actuales.where((r) => r.pictos + r.sesionesJuego > 0).length,
    serie: [
      for (final d in dias)
        (
          dia: d,
          pictos: porDia[claveDia(d)]?.pictos ?? 0,
          segundosJuego: porDia[claveDia(d)]?.segundosJuego ?? 0,
          segundosPantalla: porDia[claveDia(d)]?.apps?.totalSegundos,
        ),
    ],
    actual: _totales(actuales),
    anterior: _totales([for (final d in previos) ?porDia[claveDia(d)]]),
    categorias: _top(_sumar(actuales.map((r) => r.categorias)), nombre),
    pictos: _top(_sumar(actuales.map((r) => r.pictosUsados)), nombre),
    apps: (apps.values.toList()..sort((a, b) => b.valor.compareTo(a.valor)))
        .take(5)
        .toList(),
    segundosPantalla: conApps.fold(0, (s, r) => s + r.apps!.totalSegundos),
    diasConApps: conApps.length,
    animos: _porAnimo(enPeriodo),
  );
}

Map<int, int> _porAnimo(Iterable<MoodEntry> l) {
  final veces = <int, int>{};
  for (final m in l) {
    veces.update(m.mood, (n) => n + 1, ifAbsent: () => 1);
  }
  return veces;
}

Totales _totales(List<ResumenDia> l) => Totales(
      pictos: l.fold(0, (s, r) => s + r.pictos),
      pictosDistintos: {for (final r in l) ...r.pictosUsados.keys}.length,
      segundosJuego: l.fold(0, (s, r) => s + r.segundosJuego),
      sesionesJuego: l.fold(0, (s, r) => s + r.sesionesJuego),
      cuentos: l.fold(0, (s, r) => s + r.cuentos),
      dibujos: l.fold(0, (s, r) => s + r.dibujos),
      actividades: l.fold(0, (s, r) => s + r.actividadesHechas.length),
    );

Map<String, int> _sumar(Iterable<Map<String, int>> mapas) {
  final total = <String, int>{};
  for (final m in mapas) {
    m.forEach((k, v) => total.update(k, (t) => t + v, ifAbsent: () => v));
  }
  return total;
}

Ranking _top(Map<String, int> m, String Function(String) nombre) =>
    (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => (nombre: nombre(e.key), valor: e.value))
        .toList();
