import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/inicio/inicio_screen.dart';
import 'package:bluetalk/features/inicio/menu_centrado.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

/// Menú principal (plan 14A): carrusel, flechas, toque y TalkBack.
Future<ProviderContainer> _pump(
  WidgetTester tester, {
  bool talkBack = false,
  String apodo = 'Sol',
}) async {
  SharedPreferences.setMockInitialValues({'guia_vista': true});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(path: '/inicio', builder: (_, _) => const InicioScreen()),
      GoRoute(path: '/home/:s', builder: (_, s) => Text('en ${s.uri}')),
      GoRoute(path: '/padre', builder: (_, _) => const Text('en /padre')),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          ChildProfile(id: 'local', nickname: apodo),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(accessibleNavigation: talkBack),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(InicioScreen)));
}

void main() {
  testWidgets('saluda con el apodo y empieza en Comunicar', (tester) async {
    final c = await _pump(tester);
    expect(find.text('¡Hola, Sol! 👋'), findsOneWidget);
    expect(c.read(menuCentradoProvider), 0);
  });

  testWidgets('sin apodo saluda sin nombre', (tester) async {
    await _pump(tester, apodo: '');
    expect(find.text('¡Hola! 👋'), findsOneWidget);
  });

  testWidgets('la flecha centra la siguiente; tocar la central entra', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.tap(find.byTooltip('Siguiente'));
    await tester.pumpAndSettle();
    expect(c.read(menuCentradoProvider), 1);

    await tester.tap(find.text('Aprender'));
    await tester.pumpAndSettle();
    expect(find.text('en /home/aprender'), findsOneWidget);
  });

  testWidgets('tocar una vecina la centra sin entrar', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Aprender'));
    await tester.pumpAndSettle();
    expect(c.read(menuCentradoProvider), 1);
    expect(find.byType(InicioScreen), findsOneWidget);
  });

  testWidgets('el último es Modo padre y lleva a /padre', (tester) async {
    final c = await _pump(tester);
    c.read(menuCentradoProvider.notifier).ir(4);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.keyboard_arrow_down),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Modo padre'));
    await tester.pumpAndSettle();
    expect(find.text('en /padre'), findsOneWidget);
  });

  testWidgets('con TalkBack el menú es una lista con los 5 botones', (
    tester,
  ) async {
    await _pump(tester, talkBack: true);
    expect(find.byType(PageView), findsNothing);
    for (final t in ['Comunicar', 'Aprender', 'Rutinas', 'Ajustes']) {
      expect(find.text(t), findsOneWidget);
    }
  });
}
