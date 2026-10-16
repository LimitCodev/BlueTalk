import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bluetalk/main.dart' as app;

/// Perfilado del scroll de la rejilla del comunicador en el dispositivo o
/// emulador (plan 11 §1.3.2): se ejecuta con `flutter drive --profile` y
/// las cifras de frames salen del timeline de Dart, no de simulaciones.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scroll de la rejilla del comunicador', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // `flutter drive` puede instalar la app limpia: si aún no hay perfil,
    // se completa el onboarding sin apodo para llegar a la rejilla.
    final sinApodo = find.text('Entrar sin apodo');
    if (sinApodo.evaluate().isNotEmpty) {
      await tester.tap(sinApodo);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    final rejilla = find.byType(GridView);
    final binding = tester.binding as IntegrationTestWidgetsFlutterBinding;
    await binding.traceAction(
      () async {
        for (var i = 0; i < 12; i++) {
          await tester.drag(rejilla, const Offset(0, -260));
          await tester.pump(const Duration(milliseconds: 120));
          await tester.drag(rejilla, const Offset(0, 260));
          await tester.pump(const Duration(milliseconds: 120));
        }
      },
      reportKey: 'scroll_rejilla',
    );
  });
}
