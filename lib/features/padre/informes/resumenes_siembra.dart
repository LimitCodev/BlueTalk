import '../../../data/models/models.dart';
import 'acumular_evento.dart';
import 'dia.dart';
import 'resumen_dia.dart';
import 'resumenes_repo.dart';

/// Primera vez: rellena los resúmenes con los eventos sueltos que ya había
/// (14 días). Solo días sin resumen, para no contar dos veces el de hoy.
extension ResumenesSiembra on ResumenesRepo {
  Future<void> sembrarUnaVez(List<UsageEvent> eventos) async {
    if (sembrado) return;
    final nuevos = <String, ResumenDia>{};
    for (final e in eventos) {
      final clave = claveDia(e.createdAt);
      if (dia(clave) != null) continue;
      nuevos[clave] = acumular(nuevos[clave], e);
    }
    for (final r in nuevos.values) {
      await guardar(r);
    }
    await marcarSembrado();
  }
}
