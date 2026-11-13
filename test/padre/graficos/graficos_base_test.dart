import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/graficos/anillo_porcentaje.dart';
import 'package:bluetalk/features/padre/graficos/dona.dart';
import 'package:bluetalk/features/padre/graficos/tarjeta_grafico.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool animar = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: !animar),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('geometría de la dona', () {
    test('reparte 2π entre los valores', () {
      final angulos = angulosDona([1, 1, 2]);
      expect(angulos, hasLength(3));
      expect(angulos[0].inicio, 0);
      expect(angulos[0].barrido, closeTo(3.141592653589793 / 2, 1e-9));
      final suma = angulos.fold<double>(0, (s, a) => s + a.barrido);
      expect(suma, closeTo(6.283185307179586, 1e-9));
      expect(angulos.last.inicio + angulos.last.barrido, closeTo(6.283185307179586, 1e-9));
    });

    test('sin valores positivos no hay ángulos', () {
      expect(angulosDona([]), isEmpty);
      expect(angulosDona([0, 0]), isEmpty);
    });

    test('con más de cuatro grupos, los menores van a Otras', () {
      final datos = [
        for (var i = 0; i < 6; i++) (etiqueta: 'g$i', valor: i + 1),
      ];
      final agrupados = agruparDona(datos);
      expect(agrupados, hasLength(5));
      expect(agrupados.take(4).map((d) => d.valor), [6, 5, 4, 3]);
      expect(agrupados.last.etiqueta, 'Otras');
      expect(agrupados.last.valor, 3, reason: '1 + 2');
    });

    test('con cuatro grupos o menos no aparece Otras', () {
      final datos = [
        for (var i = 0; i < 4; i++) (etiqueta: 'g$i', valor: i + 1),
      ];
      expect(agruparDona(datos).map((d) => d.etiqueta), ['g3', 'g2', 'g1', 'g0']);
    });
  });

  group('anillo de porcentaje', () {
    test('la fracción queda entre 0 y 1', () {
      expect(fraccion(4, 6), closeTo(0.6666, 0.001));
      expect(fraccion(5, 4), 1);
      expect(fraccion(-1, 4), 0);
      expect(fraccion(4, 0), 0);
      expect(fraccion(0, 0), 0);
    });

    testWidgets('muestra el porcentaje y lo anuncia', (tester) async {
      final semantica = tester.ensureSemantics();
      await _pump(
        tester,
        const AnilloPorcentaje(
          hechas: 4,
          total: 6,
          descripcion: 'Actividades de hoy: 4 de 6, 67 por ciento',
        ),
      );
      expect(find.text('67 %'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Actividades de hoy: 4 de 6, 67 por ciento'),
        findsOneWidget,
      );
      semantica.dispose();
    });
  });

  group('marco de tarjeta', () {
    testWidgets('sin datos muestra el texto amable y nada de círculo',
        (tester) async {
      final semantica = tester.ensureSemantics();
      await _pump(
        tester,
        const TarjetaGrafico(
          pregunta: '¿Cuántas actividades hizo hoy?',
          numero: '0 de 0',
          frase: 'Sin actividades',
          semantica: 'Sin actividades',
          hayDatos: false,
        ),
      );
      expect(
        find.text(
          'Aún no hay datos. Aparecerán cuando tu hijo o hija use la app.',
        ),
        findsOneWidget,
      );
      expect(find.byType(AnilloPorcentaje), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('Aún no hay datos')),
        findsOneWidget,
      );
      semantica.dispose();
    });
  });

  testWidgets('tocar un segmento de la dona muestra su nombre y valor',
      (tester) async {
    await _pump(
      tester,
      const Dona(
        descripcion: 'Temas de hoy: Comida 3, Animales 1. Total 4.',
        porciones: [
          (etiqueta: 'Comida', valor: 3, color: Colors.orange),
          (etiqueta: 'Animales', valor: 1, color: Colors.green),
        ],
      ),
    );
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byType(Dona)) + const Offset(0, -60),
    );
    await tester.pump();
    expect(find.text('Comida'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
