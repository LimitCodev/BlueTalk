import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/plataforma/edicion.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../reloj.dart';
import 'captura_apps.dart';
import 'construir_informe.dart';
import 'informe_modelo.dart';

/// Informe del periodo que termina hoy. Antes de calcularlo siembra los
/// resúmenes (primera vez) y copia el uso de apps que Android conserva.
final informeProvider =
    FutureProvider.autoDispose.family<Informe, Periodo>((ref, periodo) async {
  final ahora = ref.watch(relojProvider)();
  final repo = ref.watch(resumenesRepoProvider);
  await repo.sembrarUnaVez(await ref.watch(usageRepoProvider).events());
  if (ref.watch(edicionDirectaProvider)) {
    await capturarUsoApps(
      gateway: ref.watch(usoTelefonoGatewayProvider),
      repo: repo,
      ahora: ahora,
    );
  }
  final pictos = ref.watch(pictogramRepoProvider);
  final categorias = await pictos.categories();
  final nombres = <String, String>{
    for (final c in categorias) c.id: c.name,
    for (final c in categorias)
      for (final p in await pictos.pictogramsOf(c.id)) p.id: p.label,
  };
  final desde = ahora.subtract(Duration(days: periodo.dias * 2));
  return construirInforme(
    periodo: periodo,
    hasta: ahora,
    resumenes: repo.rango(desde, ahora),
    animos: await ref.watch(wellbeingRepoProvider).moods(),
    nombres: nombres,
  );
});
