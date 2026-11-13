import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/graficos/tarjeta_kpi.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  test('la variación maneja cero, iguales, subida y bajada', () {
    expect(variacion(0, 0), (porcentaje: 0, direccion: 0));
    expect(variacion(5, 0), (porcentaje: null, direccion: 1));
    expect(variacion(10, 10), (porcentaje: 0, direccion: 0));
    expect(variacion(12, 10), (porcentaje: 20, direccion: 1));
    expect(variacion(8, 10), (porcentaje: -20, direccion: -1));
  });

  testWidgets('la tarjeta muestra la subida, la bajada y «Nuevo»',
      (tester) async {
    await _pump(
      tester,
      const TarjetaKpi(
        titulo: 'Pictogramas',
        valor: '12',
        actual: 12,
        anterior: 10,
        periodo: 'la semana pasada',
      ),
    );
    expect(find.text('+20 % respecto a la semana pasada'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    await _pump(
      tester,
      const TarjetaKpi(
        titulo: 'Pictogramas',
        valor: '8',
        actual: 8,
        anterior: 10,
        periodo: 'la semana pasada',
      ),
    );
    expect(find.text('-20 % respecto a la semana pasada'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

    await _pump(
      tester,
      const TarjetaKpi(
        titulo: 'Pictogramas',
        valor: '5',
        actual: 5,
        anterior: 0,
        periodo: 'la semana pasada',
      ),
    );
    expect(find.text('Nuevo respecto a la semana pasada'), findsOneWidget);
  });

  testWidgets('sin periodo anterior no inventa comparación', (tester) async {
    await _pump(
      tester,
      const TarjetaKpi(titulo: 'Sesiones de juego', valor: '3'),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });
}
