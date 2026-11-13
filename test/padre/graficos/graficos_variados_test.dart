import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/graficos/barra_apilada.dart';
import 'package:bluetalk/features/padre/graficos/calendario_calor.dart';
import 'package:bluetalk/features/padre/graficos/linea_tendencia.dart';
import 'package:bluetalk/features/padre/graficos/medidor.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
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
  test('el medidor pone el 50 % en el centro y se acota', () {
    expect(anguloMedidor(10, 10), 0);
    expect(anguloMedidor(0, 10), closeTo(-math.pi / 2, 1e-9));
    expect(anguloMedidor(20, 10), closeTo(math.pi / 2, 1e-9));
    expect(anguloMedidor(50, 10), closeTo(math.pi / 2, 1e-9));
    expect(anguloMedidor(5, 0), closeTo(math.pi / 2, 1e-9));
  });

  test('la línea normaliza al máximo y no divide entre cero', () {
    final puntos = puntosLinea([1, 2], const Size(100, 50));
    expect(puntos.first, const Offset(0, 25));
    expect(puntos.last, const Offset(100, 0));

    final ceros = puntosLinea([0, 0], const Size(100, 50));
    expect(ceros.every((p) => p.dy == 50), isTrue);

    final uno = puntosLinea([5], const Size(100, 50));
    expect(uno.single, const Offset(50, 0));
    expect(puntosLinea([], const Size(100, 50)), isEmpty);
  });

  test('el calendario reparte cuatro niveles de calor', () {
    expect(nivelCalor(0, 10), 0);
    expect(nivelCalor(1, 10), 1);
    expect(nivelCalor(2, 10), 1);
    expect(nivelCalor(3, 10), 2);
    expect(nivelCalor(5, 10), 2);
    expect(nivelCalor(6, 10), 3);
    expect(nivelCalor(8, 10), 4);
    expect(nivelCalor(10, 10), 4);
    expect(nivelCalor(5, 0), 0);
  });

  test('la barra apilada reparte 100 % sin perder puntos', () {
    expect(porcentajes([2, 1, 1]), [50, 25, 25]);
    expect(porcentajes([1, 1, 1]).fold<int>(0, (s, n) => s + n), 100);
    expect(porcentajes([0, 0]), [0, 0]);
    expect(porcentajes([7]), [100]);
    expect(porcentajes([]), isEmpty);
  });

  testWidgets('el medidor se anuncia con su comparación', (tester) async {
    final semantica = tester.ensureSemantics();
    await _pump(
      tester,
      const Medidor(
        actual: 12,
        anterior: 10,
        descripcion: 'Pictogramas: 12 ahora, 10 antes',
      ),
    );
    expect(
      find.bySemanticsLabel('Pictogramas: 12 ahora, 10 antes'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('el medidor ocupa el ancho de su tarjeta', (tester) async {
    // Sin esto el lienzo medía 0 de ancho y no se dibujaba nada.
    await _pump(
      tester,
      const SizedBox(
        width: 300,
        child: Medidor(actual: 12, anterior: 10, descripcion: 'x'),
      ),
    );
    final lienzo = find.descendant(
      of: find.byType(Medidor),
      matching: find.byType(CustomPaint),
    );
    expect(tester.getSize(lienzo).width, 300);
  });

  testWidgets('la línea muestra el último día y cambia al tocar',
      (tester) async {
    await _pump(
      tester,
      const LineaTendencia(
        valores: [1, 2, 3],
        etiquetas: ['Lun', 'Mar', 'Mié'],
        descripcion: 'Pictogramas por día: 1, 2, 3',
      ),
    );
    expect(find.text('Mié: 3'), findsOneWidget);

    await tester.tapAt(
      tester.getTopLeft(find.byType(LineaTendencia)) + const Offset(10, 80),
    );
    await tester.pump();
    expect(find.text('Lun: 1'), findsOneWidget);
  });

  testWidgets('el calendario pinta los días y se anuncia', (tester) async {
    final semantica = tester.ensureSemantics();
    await _pump(
      tester,
      CalendarioCalor(
        dias: [for (var i = 0; i < 7; i++) DateTime(2026, 10, 1 + i)],
        valores: const [0, 1, 2, 3, 4, 5, 6],
        descripcion: 'Días usados en octubre: 1, 2, 3, 4, 5, 6, 7',
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Días usados en octubre: 1, 2, 3, 4, 5, 6, 7'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('la barra apilada muestra icono y porcentaje por segmento',
      (tester) async {
    final semantica = tester.ensureSemantics();
    await _pump(
      tester,
      const BarraApilada(
        descripcion: 'Ánimo: Feliz 50 por ciento, Tranquilo 25, Triste 25',
        segmentos: [
          (etiqueta: 'Feliz', valor: 2, icono: Icons.sentiment_very_satisfied, color: Colors.green),
          (etiqueta: 'Tranquilo', valor: 1, icono: Icons.sentiment_satisfied, color: Colors.blue),
          (etiqueta: 'Triste', valor: 1, icono: Icons.sentiment_dissatisfied, color: Colors.orange),
        ],
      ),
    );
    expect(find.text('Feliz 50 %'), findsOneWidget);
    expect(find.text('Tranquilo 25 %'), findsOneWidget);
    expect(find.text('Triste 25 %'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Ánimo: Feliz 50 por ciento, Tranquilo 25, Triste 25',
      ),
      findsOneWidget,
    );
    semantica.dispose();
  });
}
