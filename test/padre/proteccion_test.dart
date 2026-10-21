import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/proteccion/proteccion_controller.dart';
import 'package:bluetalk/features/padre/proteccion/proteccion_gateway.dart';
import 'package:bluetalk/features/padre/proteccion/proteccion_tile.dart';

import '../core/accessibility_helper.dart';

/// Doble de sistema: simula que Android acepta o rechaza la activación.
class _ProteccionFalsa implements ProteccionGateway {
  _ProteccionFalsa({this.activo = false, this.puedeActivar = true});

  bool activo;
  int activaciones = 0;
  int desactivaciones = 0;
  bool puedeActivar;

  @override
  Future<ProteccionEstado> estado() async => ProteccionEstado(activo: activo);

  @override
  Future<bool> pedirActivacion() async {
    activaciones++;
    if (puedeActivar) activo = true;
    return puedeActivar;
  }

  @override
  Future<void> desactivar() async {
    desactivaciones++;
    activo = false;
  }
}

Widget _pantalla(List<Object> overrides) => ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(home: Scaffold(body: ProteccionTile())),
    );

void main() {
  group('protección contra desinstalación', () {
    test('sin canal nativo se reporta inactiva, nunca fingida', () async {
      // En `flutter test` no hay canal `bluetalk/proteccion`: el gateway
      // real tiene que devolver «sin protección», no «protegida».
      final estado = await const PlatformProteccionGateway().estado();

      expect(estado.activo, isFalse);
    });

    testWidgets('la fila enseña que está sin activar', (tester) async {
      final falso = _ProteccionFalsa();

      await tester.pumpWidget(
        _pantalla([proteccionGatewayProvider.overrideWithValue(falso)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protección contra desinstalación'), findsOneWidget);
      expect(find.textContaining('Sin activar'), findsOneWidget);
    });

    testWidgets('tocar la fila pide la activación al sistema', (tester) async {
      final falso = _ProteccionFalsa();

      await tester.pumpWidget(
        _pantalla([proteccionGatewayProvider.overrideWithValue(falso)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Protección contra desinstalación'));
      await tester.pumpAndSettle();

      expect(falso.activaciones, 1);
      expect(find.textContaining('Activa'), findsOneWidget);
    });

    testWidgets('si el sistema rechaza, la casilla no finge que está activa',
        (tester) async {
      final falso = _ProteccionFalsa(puedeActivar: false);

      await tester.pumpWidget(
        _pantalla([proteccionGatewayProvider.overrideWithValue(falso)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Protección contra desinstalación'));
      await tester.pumpAndSettle();

      expect(falso.activaciones, 1);
      expect(find.textContaining('Sin activar'), findsOneWidget);
    });

    testWidgets('quitar la protección pide confirmación antes', (tester) async {
      final falso = _ProteccionFalsa(activo: true);

      await tester.pumpWidget(
        _pantalla([proteccionGatewayProvider.overrideWithValue(falso)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Protección contra desinstalación'));
      await tester.pumpAndSettle();

      expect(falso.desactivaciones, 0, reason: 'aún no se ha confirmado');
      expect(find.text('¿Quitar la protección?'), findsOneWidget);

      await tester.tap(find.text('Dejarla puesta'));
      await tester.pumpAndSettle();
      expect(falso.desactivaciones, 0);

      await tester.tap(find.text('Protección contra desinstalación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitarla'));
      await tester.pumpAndSettle();

      expect(falso.desactivaciones, 1);
      expect(find.textContaining('Sin activar'), findsOneWidget);
    });
  });

  testWidgets('la casilla de protección es accesible', (tester) async {
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: [proteccionGatewayProvider.overrideWithValue(
        _ProteccionFalsa(activo: true),
      )],
      home: const Scaffold(body: ProteccionTile()),
    );
  });
}
