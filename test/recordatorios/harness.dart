import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorio_scheduler.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorio_scheduler_real.dart';
import 'package:bluetalk/features/rutinas/recordatorios/recordatorios_controller.dart';

import '../rutinas/harness.dart';

export '../rutinas/harness.dart' show overridesDeRutinas, prefsDePrueba;

/// Doble falso de scheduler (plan 1.1): registra cada llamada.
class DobleRecordatorioScheduler implements RecordatorioScheduler {
  /// Avisos programados ahora mismo (id de notificación → entrada).
  final programadas = <int, ScheduleEntry>{};

  /// Ids de actividad cancelados, en orden.
  final canceladas = <String>[];

  /// Cuántas veces se ha llamado a `programar` por id.
  final conteoProgramar = <int, int>{};

  var cancelarTodosLlamado = 0;
  var permisoConcedido = true;
  var permisoPedido = 0;

  @override
  Future<void> programar(ScheduleEntry entrada) async {
    final id = idNotificacion(entrada.id);
    programadas[id] = entrada;
    conteoProgramar[id] = (conteoProgramar[id] ?? 0) + 1;
  }

  @override
  Future<void> cancelar(String entryId) async {
    canceladas.add(entryId);
    programadas.remove(idNotificacion(entryId));
  }

  @override
  Future<void> cancelarTodos() async {
    cancelarTodosLlamado++;
    programadas.clear();
  }

  @override
  Future<bool> pedirPermiso() async {
    permisoPedido++;
    return permisoConcedido;
  }

  @override
  Future<bool> estaPermitido() async => permisoConcedido;
}

/// Container con prefs de prueba, seeds del disco y el doble de scheduler;
/// mantiene vivo el sincronizador y espera su primera pasada.
Future<(ProviderContainer, DobleRecordatorioScheduler)>
    contenedorRecordatorios({bool permiso = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await prefsDePrueba();
  final doble = DobleRecordatorioScheduler()..permisoConcedido = permiso;
  final container = ProviderContainer(
    overrides: [
      ...overridesDeRutinas(prefs),
      recordatorioSchedulerProvider.overrideWithValue(doble),
    ].cast(),
  );
  addTearDown(container.dispose);
  container.listen(recordatoriosProvider, (_, _) {});
  await asentar();
  return (container, doble);
}

/// Deja terminar microtareas y timers de cero pendientes.
Future<void> asentar([int veces = 6]) async {
  for (var i = 0; i < veces; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
