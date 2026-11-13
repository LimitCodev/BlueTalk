import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/graficos/animacion.dart';
import 'package:bluetalk/features/padre/informes/grafica_columnas.dart';
import 'package:bluetalk/features/padre/informes/grafica_columnas_pintor.dart';

Future<void> _pumpConCalma(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('con calma, un solo pump deja la animación en 1',
      (tester) async {
    double? avance;
    await _pumpConCalma(
      tester,
      AnimacionGrafico(
        builder: (context, t) {
          avance = t;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(avance, 1);
  });

  testWidgets('con calma, las columnas ya están en su valor final',
      (tester) async {
    await _pumpConCalma(
      tester,
      const GraficaColumnas(
        valores: [1, 2, 3],
        descripcion: 'Eventos por día: 1, 2, 3',
        etiquetas: ['Lun', 'Mar', 'Mié'],
      ),
    );
    final pintura = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(GraficaColumnas),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect((pintura.painter as PintorColumnas).progreso, 1);
    expect(find.text('Mié: 3'), findsOneWidget);
  });

  testWidgets('tocar una columna muestra su día y su valor', (tester) async {
    await _pumpConCalma(
      tester,
      const GraficaColumnas(
        valores: [1, 2, 3],
        descripcion: 'Eventos por día: 1, 2, 3',
        etiquetas: ['Lun', 'Mar', 'Mié'],
        unidad: 'eventos',
      ),
    );
    expect(find.text('Mié: 3 eventos'), findsOneWidget);

    await tester.tapAt(
      tester.getTopLeft(find.byType(GraficaColumnas)) + const Offset(10, 80),
    );
    await tester.pump();
    expect(find.text('Lun: 1 eventos'), findsOneWidget);
  });

  testWidgets('la gráfica se anuncia con su descripción completa',
      (tester) async {
    final semantica = tester.ensureSemantics();
    await _pumpConCalma(
      tester,
      const GraficaColumnas(
        valores: [1, 2, 3],
        descripcion: 'Pictogramas por día: 1, 2, 3',
      ),
    );
    expect(
      find.bySemanticsLabel('Pictogramas por día: 1, 2, 3'),
      findsOneWidget,
    );
    semantica.dispose();
  });
}
