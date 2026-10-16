import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/widgets/logo_bluetalk.dart';

void main() {
  testWidgets('el logo oficial se dibuja con su painter (plan 13 P3.2)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: LogoBluetalk(size: 64))),
      ),
    );

    // Se pinta sin excepciones y con tamaño exacto (escalable).
    final pintor = find.descendant(
      of: find.byType(LogoBluetalk),
      matching: find.byType(CustomPaint),
    );
    expect(pintor, findsOneWidget);
    final caja = tester.getSize(find.byType(LogoBluetalk));
    expect(caja.width, 64);
    expect(caja.height, 64);
  });
}
