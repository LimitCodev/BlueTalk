import '../monitoreo/uso_telefono_gateway.dart';
import 'acumular_evento.dart';
import 'dia.dart';
import 'resumen_dia.dart';
import 'resumenes_repo.dart';

/// Android borra el detalle diario de uso a los 10 días
/// (`UsageStatsDatabase.prune`, AOSP). Para que el informe mensual tenga
/// el mes entero, se copia aquí lo que Android aún conserva cada vez que
/// se abren los informes.
const diasQueConservaAndroid = 9;

/// Copia el uso de otras apps de los últimos días. Devuelve los días leídos.
///
/// Hoy y ayer se releen siempre (pueden seguir cambiando); los anteriores
/// solo si aún no se habían copiado. Sin permiso no lee nada.
Future<int> capturarUsoApps({
  required UsoTelefonoGateway gateway,
  required ResumenesRepo repo,
  required DateTime ahora,
  int maxApps = 10,
}) async {
  if (!await gateway.estaPermitido()) return 0;
  final ayer = DateTime(ahora.year, ahora.month, ahora.day - 1);
  var leidos = 0;
  for (final dia in diasHasta(ahora, diasQueConservaAndroid)) {
    final clave = claveDia(dia);
    final reciente = !dia.isBefore(ayer);
    if (!reciente && repo.dia(clave)?.apps != null) continue;
    final fin = DateTime(dia.year, dia.month, dia.day + 1);
    final uso = await gateway.resumen(dia, fin.isAfter(ahora) ? ahora : fin);
    if (!uso.permiso) break;
    // Se relee tras el `await`: un toque del niño en medio no se pierde.
    final actual = repo.dia(clave) ?? ResumenDia(dia: clave);
    await repo.guardar(conApps(
      actual,
      UsoAppsDia(
        totalSegundos: uso.totalSegundos,
        apps: {
          for (final app in uso.apps.take(maxApps))
            app.paquete: (nombre: app.nombre, segundos: app.segundos),
        },
      ),
    ));
    leidos++;
  }
  return leidos;
}
