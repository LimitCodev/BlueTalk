import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/app/router.dart';
import 'package:bluetalk/app/shell.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/juegos/juegos_screen.dart';
import 'package:bluetalk/features/padre/legal/legal_screen.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

import '../comunicador/dobles.dart';

Future<SharedPreferences> _givenPrefs() => _givenPrefsCon({});

Future<SharedPreferences> _givenPrefsCon(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  SharedPreferences prefs, {
  ChildProfile? profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (profile != null)
          initialProfileProvider.overrideWithValue(profile),
        // El shell aloja el comunicador real: seeds leídas del disco y TTS
        // falso para que el test sea hermético (el canal de assets de
        // flutter test solo responde en el primer testWidgets del archivo).
        ttsSpeakerProvider.overrideWithValue(FakeTtsSpeaker()),
        seedStoreProvider.overrideWithValue(
          SeedStore(
            (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
          ),
        ),
      ],
      child: const BlueTalkApp(),
    ),
  );
  return ProviderScope.containerOf(tester.element(find.byType(BlueTalkApp)));
}

/// Completa el onboarding escribiendo un apodo (sin PII).
Future<void> _completarOnboarding(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Sol');
  // El botón se habilita en el rebuild posterior a onChanged.
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding: pide apodo y entra al shell', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    expect(find.text('¿Cómo te llamas?'), findsOneWidget);
    // Sin apodo el botón está deshabilitado (no avanza vacío).
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Comenzar'))
          .onPressed,
      isNull,
    );

    await _completarOnboarding(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Comunicar'), findsWidgets); // AppBar + pestaña
    expect(find.text('¿Cómo te llamas?'), findsNothing);

    // El perfil quedó guardado localmente.
    final saved = await PrefsProfileRepo(prefs).currentProfile();
    expect(saved, isNotNull);
    expect(saved!.nickname, 'Sol');
  });

  testWidgets('con perfil guardado arranca directo en el home', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsNothing);
  });

  testWidgets('el apodo es opcional: se puede entrar sin él', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    await tester.tap(find.text('Entrar sin apodo'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    final saved = await PrefsProfileRepo(prefs).currentProfile();
    expect(saved, isNotNull, reason: 'aunque sin apodo sí se crea el perfil');
  });

  testWidgets('las pestañas navegan y el botón del shell activa el modo calma',
      (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    await _completarOnboarding(tester);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.byType(CalmModeToggle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(prefs.getBool(CalmModeController.prefKey), isTrue);
  });

  testWidgets('ruta /padre muestra la legal la primera vez', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    container.read(routerProvider).go('/padre');
    await tester.pumpAndSettle();

    // Sin legal aceptada: vista legal dentro del PadreScreen (AppBar + botón).
    expect(find.text('Modo padre'), findsOneWidget);
    expect(find.byType(LegalScreen), findsOneWidget);
  });

  testWidgets('modo calma: las rutas cambian con duración cero',
      (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    await container.read(calmModeProvider.notifier).set(true);
    await tester.pump();

    container.read(routerProvider).go('/home/aprender');
    await tester.pumpAndSettle();

    final calmRoute = ModalRoute.of(
      tester.element(find.byType(JuegosScreen)),
    );
    expect(calmRoute, isNotNull);
    expect(calmRoute!.transitionDuration, Duration.zero);

    // Sin modo calma la transición normal sí existe.
    await container.read(calmModeProvider.notifier).set(false);
    await tester.pump();
    container.read(routerProvider).go('/home/rutinas');
    await tester.pumpAndSettle();

    final normalRoute = ModalRoute.of(
      tester.element(find.text('Mi horario')),
    );
    expect(normalRoute!.transitionDuration, isNot(Duration.zero));
  });

  testWidgets('juegos bloqueados por un adulto muestran el aviso suave',
      (tester) async {
    final prefs = await _givenPrefsCon({'padre_bloqueo_juegos': true});
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    container.read(routerProvider).go('/home/aprender');
    await tester.pumpAndSettle();

    expect(
      find.text('Los juegos están bloqueados por un adulto.'),
      findsOneWidget,
    );
    expect(find.byType(JuegosScreen), findsNothing);
  });

  testWidgets('tiempo de juegos agotado muestra el aviso con salida',
      (tester) async {
    final prefs = await _givenPrefsCon({
      'padre_limite_juegos_min': 15,
      'bluetalk_usage': jsonEncode([
        {
          'id': 'j1',
          'type': 'juego_fin',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'data': {'segundos': 1000},
        },
      ]),
    });
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    container.read(routerProvider).go('/home/aprender');
    await tester.pumpAndSettle();

    expect(
      find.text('El tiempo de juegos de hoy terminó.'),
      findsOneWidget,
    );
    expect(find.byType(JuegosScreen), findsNothing);
  });

  testWidgets('colegio bloqueado por un adulto muestra el aviso y vuelve',
      (tester) async {
    final prefs = await _givenPrefsCon({'padre_bloqueo_entorno': true});
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    await tester.tap(find.text('Rutinas'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Mi colegio'));
    await tester.tap(find.text('Mi colegio'));
    await tester.pumpAndSettle();

    expect(
      find.text('La sección Mi colegio está bloqueada por un adulto.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Mi horario'), findsOneWidget);
  });
}
