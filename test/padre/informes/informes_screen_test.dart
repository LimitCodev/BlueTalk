import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/graficos/linea_tendencia.dart';
import 'package:bluetalk/features/padre/informes/grafica_columnas.dart';
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

    expect(find.text('¿Cómo va comparado con antes?'), findsOneWidget);
    expect(find.textContaining('No es un diagnóstico'), findsOneWidget);

    final listaSemana = find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.text('¿Cómo cambió la comunicación día a día?'),
      300,
      scrollable: listaSemana,
    );
    expect(find.bySemanticsLabel(RegExp('^Pictogramas por día')), findsOneWidget);
    expect(find.byType(GraficaColumnas), findsWidgets,
        reason: 'la semana se lee en columnas');
    await tester.scrollUntilVisible(
      find.text('¿En qué apps pasó el tiempo?'),
      300,
      scrollable: listaSemana,
    );
    expect(find.text('¿En qué apps pasó el tiempo?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Manzana'),
      300,
      scrollable: listaSemana,
    );
    expect(find.text('Manzana'), findsOneWidget, reason: 'nombre del seed');
    await tester.scrollUntilVisible(
      find.text('Copiar informe'),
      300,
      scrollable: listaSemana,
    );
    await tester.tap(find.text('Copiar informe'));
    await tester.pumpAndSettle();
    expect(copiado, startsWith('Informe semanal de BlueTalk'));
    expect(copiado, contains('Uso del teléfono'));
    expect(find.textContaining('Informe copiado'), findsOneWidget);

    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    final listaMes = find
        .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
      find.byType(LineaTendencia),
      300,
      scrollable: listaMes,
    );
    expect(find.byType(LineaTendencia), findsOneWidget,
        reason: 'el mes se lee como línea de tendencia');
    await tester.scrollUntilVisible(
      find.text('¿Qué días usó la app?'),
      300,
      scrollable: listaMes,
    );
    expect(find.text('¿Qué días usó la app?'), findsOneWidget,
        reason: 'el mes incluye calendario de calor');
    await tester.scrollUntilVisible(
      find.text('Por semana'),
      300,
      scrollable: listaMes,
    );
    expect(find.text('Por semana'), findsOneWidget);
    semantica.dispose();
  });
}
