import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/monitoreo/uso_telefono_controller.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_gateway.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_model.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_screen.dart';

import 'harness.dart';

class _GatewayUsoFalso implements UsoTelefonoGateway {
  _GatewayUsoFalso({this.permiso = true, this.datos});

  bool permiso;
  bool abrirOk = true;
  ResumenUso? datos;
  int aperturas = 0;
  final consultas = <({DateTime desde, DateTime hasta})>[];

  @override
  Future<bool> estaPermitido() async => permiso;

  @override
  Future<bool> abrirAjustes() async {
    aperturas++;
    return abrirOk;
  }

  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async {
    consultas.add((desde: desde, hasta: hasta));
    return datos ??
        ResumenUso(
          permiso: permiso,
          totalSegundos: 0,
          apps: const [],
          desde: desde,
          hasta: hasta,
        );
  }
}

void main() {
  group('formatearDuracion', () {
    test('usa textos literales y sin decimales', () {
      expect(formatearDuracion(0), '0 min');
      expect(formatearDuracion(-30), '0 min');
      expect(formatearDuracion(59), 'menos de 1 min');
      expect(formatearDuracion(60), '1 min');
      expect(formatearDuracion(45 * 60), '45 min');
      expect(formatearDuracion(60 * 60), '1 h');
      expect(formatearDuracion(2 * 3600 + 15 * 60), '2 h 15 min');
    });
  });

  group('ResumenUso', () {
    test('lee el mapa nativo, ordena por tiempo y tolera datos rotos', () {
      final resumen = ResumenUso.fromMap({
        'permiso': true,
        'totalSegundos': 8100,
        'desde': 1000,
        'hasta': 2000,
        'apps': [
          {'paquete': 'com.youtube', 'nombre': 'YouTube', 'segundos': 900},
          'no es un mapa',
          {'paquete': 'com.tiktok', 'nombre': 'TikTok', 'segundos': 7200},
        ],
      });

      expect(resumen.permiso, isTrue);
      expect(resumen.totalSegundos, 8100);
      expect(resumen.apps.map((app) => app.nombre), ['TikTok', 'YouTube']);
      expect(resumen.appPrincipal?.paquete, 'com.tiktok');
      expect(resumen.segundosApps, 8100);
      expect(resumen.desde.millisecondsSinceEpoch, 1000);
      expect(resumen.hasta.millisecondsSinceEpoch, 2000);
    });

    test('sin permiso no inventa apps ni tiempo', () {
      final resumen = ResumenUso.sinPermiso(
        DateTime(2026, 10, 13),
        DateTime(2026, 10, 13, 10),
      );
      expect(resumen.permiso, isFalse);
      expect(resumen.totalSegundos, 0);
      expect(resumen.apps, isEmpty);
      expect(resumen.appPrincipal, isNull);
    });

    test('un mapa vacío no rompe la pantalla', () {
      final resumen = ResumenUso.fromMap(const {});
      expect(resumen.permiso, isFalse);
      expect(resumen.apps, isEmpty);
      expect(resumen.totalSegundos, 0);
    });
  });

  group('resumenUsoProvider', () {
    test('hoy consulta desde la medianoche hasta ahora', () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso();
      final container = ProviderContainer(
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );
      addTearDown(container.dispose);

      await container.read(resumenUsoProvider.future);

      expect(gateway.consultas, hasLength(1));
      expect(gateway.consultas.single.desde, DateTime(2026, 10, 13));
      expect(gateway.consultas.single.hasta, ahoraFija);
    });

    test('los últimos 7 días incluyen hoy y seis días atrás', () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso();
      final container = ProviderContainer(
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );
      addTearDown(container.dispose);

      container.read(periodoUsoProvider.notifier).set(PeriodoUso.sieteDias);
      await container.read(resumenUsoProvider.future);

      expect(gateway.consultas.single.desde, DateTime(2026, 10, 7));
      expect(gateway.consultas.single.hasta, ahoraFija);
    });
  });

  group('pantalla del adulto', () {
    testWidgets('sin permiso explica para qué sirve y lo pide en Ajustes',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso(permiso: false);
      await pumpPadre(
        tester,
        home: const UsoTelefonoScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );

      expect(find.text('Falta el permiso «Acceso al uso»'), findsOneWidget);
      expect(
        find.textContaining('Android necesita este permiso'),
        findsOneWidget,
      );

      await tester.tap(find.text('Abrir Ajustes de Android'));
      await tester.pumpAndSettle();
      expect(gateway.aperturas, 1);
    });

    testWidgets('con permiso muestra el total y el tiempo por app',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso(
        datos: ResumenUso(
          permiso: true,
          totalSegundos: 2 * 3600 + 15 * 60,
          apps: const [
            UsoApp(paquete: 'com.tiktok', nombre: 'TikTok', segundos: 7200),
            UsoApp(paquete: 'com.youtube', nombre: 'YouTube', segundos: 900),
          ],
          desde: DateTime(2026, 10, 13),
          hasta: ahoraFija,
        ),
      );
      await pumpPadre(
        tester,
        home: const UsoTelefonoScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );

      expect(find.text('2 h 15 min'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.text('2 h'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(
        find.textContaining('No incluye la pantalla apagada'),
        findsOneWidget,
      );
    });

    testWidgets('cambiar a 7 días vuelve a consultar el periodo',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso();
      await pumpPadre(
        tester,
        home: const UsoTelefonoScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );

      expect(gateway.consultas.single.desde, DateTime(2026, 10, 13));

      await tester.tap(find.text('Últimos 7 días'));
      await tester.pumpAndSettle();

      expect(gateway.consultas, hasLength(2));
      expect(gateway.consultas.last.desde, DateTime(2026, 10, 7));
    });

    testWidgets('«Ya lo activé» refresca el permiso y carga el resumen',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayUsoFalso(permiso: false);
      await pumpPadre(
        tester,
        home: const UsoTelefonoScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          usoTelefonoGatewayProvider.overrideWithValue(gateway),
        ].cast(),
      );

      expect(find.text('Falta el permiso «Acceso al uso»'), findsOneWidget);

      gateway.permiso = true;
      await tester.tap(find.text('Ya lo activé: actualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Tiempo total en apps'), findsOneWidget);
      expect(find.textContaining('No hay uso registrado'), findsOneWidget);
    });
  });
}
