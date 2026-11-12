import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';
import 'package:bluetalk/features/padre/control/control_nombre_dialogo.dart';

/// Plan 14A §A4: el adulto cambia el apodo desde el Modo padre.
Future<SharedPreferences> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: NombreDialogo())),
    ),
  );
  return prefs;
}

void main() {
  testWidgets('muestra el apodo actual y guarda el nuevo', (tester) async {
    final prefs = await _pump(tester);
    expect(find.widgetWithText(TextField, 'Sol'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NombreDialogo)),
    );

    await tester.enterText(find.byType(TextField), '  Luna ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final guardado = await PrefsProfileRepo(prefs).currentProfile();
    expect(guardado!.nickname, 'Luna', reason: 'recortado y persistido');
    expect(container.read(profileProvider)!.nickname, 'Luna');
  });

  testWidgets('vacío deja el perfil sin apodo', (tester) async {
    final prefs = await _pump(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final guardado = await PrefsProfileRepo(prefs).currentProfile();
    expect(guardado!.nickname, '');
  });

  testWidgets('Cancelar no cambia nada', (tester) async {
    final prefs = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Otro');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(
      await PrefsProfileRepo(prefs).currentProfile(),
      isNull,
      reason: 'no se guardó nada',
    );
  });
}
