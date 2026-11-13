import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/almacen/almacen_local.dart';
import 'package:bluetalk/core/plataforma/edicion.dart';
import 'package:bluetalk/features/padre/informes/informes_screen.dart';
import 'package:bluetalk/features/padre/informes/resumen_dia.dart';
import 'package:bluetalk/features/padre/informes/resumenes_repo.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_controller.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_gateway.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_model.dart';
import 'package:bluetalk/features/padre/permisos/permiso_model.dart';
import 'package:bluetalk/features/padre/reloj.dart';

/// Perfilado del informe mensual con 30 días de datos (plan 14C §5 paso 7).
///
/// `flutter drive --profile --driver=test_driver/integration_test.dart
/// --target=integration_test/perfilado_informes_test.dart`
/// El cuadro medio se mide con los tiempos reales de frame del motor.
class _GatewayFalso implements UsoTelefonoGateway {
  @override
  Future<bool> estaPermitido() async => true;

  @override
  Future<EstadoPermiso> estadoPermiso() async => EstadoPermiso.concedido;

  @override
  Future<bool> abrirAjustes() async => false;

  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async =>
      ResumenUso(
        permiso: true,
        totalSegundos: 600,
        apps: [
          for (var i = 0; i < 10; i++)
            UsoApp(paquete: 'app.$i', nombre: 'App $i', segundos: 600 - i),
        ],
        desde: desde,
        hasta: hasta,
      );
}

Future<void> _sembrar(DateTime ahora) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  final repo = ResumenesRepo(AlmacenPrefs(prefs));
  for (var i = 0; i < 60; i++) {
    final dia = ahora.subtract(Duration(days: i));
    await repo.guardar(
      ResumenDia(
        dia:
            '${dia.year}-${dia.month.toString().padLeft(2, '0')}-'
            '${dia.day.toString().padLeft(2, '0')}',
        pictos: 8 + (i % 7),
        categorias: {'comida': 4, 'acciones': 3, 'emociones': 2},
        pictosUsados: {'apple': 4, 'quiero': 2, 'feliz': 2},
        segundosJuego: 600,
        sesionesJuego: 2,
        cuentos: 1,
        dibujos: 1,
        actividadesHechas: {'desayunar', 'lavarse-dientes'},
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final ahora = DateTime(2026, 10, 13, 10);

  testWidgets('informe mensual con 30 días: cuadro medio', (tester) async {
    await _sembrar(ahora);
    final prefs = await SharedPreferences.getInstance();
    final tiempos = <FrameTiming>[];
    void registrar(List<FrameTiming> t) => tiempos.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(registrar);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          relojProvider.overrideWithValue(() => ahora),
          edicionDirectaProvider.overrideWithValue(true),
          usoTelefonoGatewayProvider.overrideWithValue(_GatewayFalso()),
        ],
        child: const MaterialApp(home: InformesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    tiempos.clear();

    final lista = find.byType(ListView).last;
    final binding = tester.binding as IntegrationTestWidgetsFlutterBinding;
    await binding.traceAction(() async {
      for (var i = 0; i < 8; i++) {
        await tester.drag(lista, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 80));
        await tester.drag(lista, const Offset(0, 300));
        await tester.pump(const Duration(milliseconds: 80));
      }
    }, reportKey: 'informes_mensual');

    SchedulerBinding.instance.removeTimingsCallback(registrar);
    double media(List<int> valores) => valores.isEmpty
        ? 0
        : valores.fold<int>(0, (s, v) => s + v) / valores.length / 1000;
    final promedio = tiempos.isEmpty
        ? 0.0
        : tiempos.fold<double>(
                0,
                (s, t) => s + t.totalSpan.inMicroseconds / 1000,
              ) /
              tiempos.length;
    final build = media([
      for (final t in tiempos) t.buildDuration.inMicroseconds,
    ]);
    final raster = media([
      for (final t in tiempos) t.rasterDuration.inMicroseconds,
    ]);
    debugPrint(
      'PERFIL informes mensual: ${tiempos.length} frames, '
      'total ${promedio.toStringAsFixed(1)} ms, '
      'build ${build.toStringAsFixed(1)} ms, '
      'raster ${raster.toStringAsFixed(1)} ms',
    );
    expect(tiempos, isNotEmpty);
    expect(
      promedio,
      lessThan(16.0),
      reason: 'el cuadro medio del mes no debe pasar de 16 ms',
    );
  });
}
