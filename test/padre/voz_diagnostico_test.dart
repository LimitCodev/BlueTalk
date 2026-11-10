import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/padre/control/voz_diagnostico.dart';

import '../comunicador/dobles.dart';

Future<void> _pump(WidgetTester tester, FakeTtsSpeaker voz) => tester.pumpWidget(
      ProviderScope(
        overrides: [ttsSpeakerProvider.overrideWithValue(voz)],
        child: const MaterialApp(home: VozDiagnosticoScreen()),
      ),
    );

void main() {
  testWidgets('sin voz en español lo dice y ofrece los ajustes', (tester) async {
    final voz = FakeTtsSpeaker(spanishAvailable: false);
    await _pump(tester, voz);
    expect(find.text('Abrir ajustes de voz'), findsNothing);

    await tester.tap(find.text('¿No se oye? Toca aquí'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no tiene voz en español'), findsOneWidget);
    expect(find.text('Abrir ajustes de voz'), findsOneWidget);
  });

  testWidgets('con voz habla solo al tocar y no avisa', (tester) async {
    final voz = FakeTtsSpeaker();
    await _pump(tester, voz);
    expect(voz.spoken, isEmpty);

    await tester.tap(find.text('¿No se oye? Toca aquí'));
    await tester.pumpAndSettle();

    expect(voz.spoken, [VozDiagnosticoScreen.frase]);
    expect(find.text('Abrir ajustes de voz'), findsNothing);
  });
}
