import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/informes/informes_screen.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../harness.dart';
import 'gateway_falso.dart';

void main() {
  testWidgets('informe semanal con gráfica, apps y copiar; luego mensual',
      (tester) async {
    final semantica = tester.ensureSemantics();
    final prefs = await prefsDePrueba();
    await sembrarEventos(prefs, [
      for (var i = 0; i < 3; i++)
        UsageEvent(
          id: 't$i',
          type: 'picto_tap',
          createdAt: ahoraFija,
          data: {'pictoId': 'apple', 'categoryId': 'comida'},
        ),
    ]);
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (llamada) async {
        if (llamada.method == 'Clipboard.setData') {
          copiado = (llamada.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );

    await pumpPadre(
      tester,
      home: const InformesScreen(),
      overrides: [
        ...overridesDePadre(prefs),
        usoTelefonoGatewayProvider.overrideWithValue(GatewayFalso()),
      ],
    );

    expect(find.textContaining('Pictogramas tocados: 3'), findsOneWidget);
    expect(find.textContaining('No es un diagnóstico'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Pictogramas por día')), findsOneWidget);
    expect(find.text('Manzana'), findsOneWidget, reason: 'nombre del seed');

    await tester.scrollUntilVisible(
      find.text('Copiar informe'),
      300,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Apps más usadas'), findsOneWidget);
    await tester.tap(find.text('Copiar informe'));
    await tester.pumpAndSettle();
    expect(copiado, startsWith('Informe semanal de BlueTalk'));
    expect(copiado, contains('Uso del teléfono'));
    expect(find.textContaining('Informe copiado'), findsOneWidget);

    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    expect(find.textContaining('de 30 días'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Por semana'),
      300,
      scrollable: find
          .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Por semana'), findsOneWidget);
    semantica.dispose();
  });
}
