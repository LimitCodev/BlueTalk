import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/ajustes/ajustes_screen.dart';
import 'package:bluetalk/features/ajustes/settings_controller.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

void main() {
  group('SettingsController', () {
    test('carga defaults y persiste cambios', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final initial = await container.read(settingsProvider.future);
      expect(initial.textScale, 1.0);
      expect(initial.ttsRate, 0.5);

      await container.read(settingsProvider.notifier).setTextScale(1.3);

      expect(
        (await container.read(settingsProvider.future)).textScale,
        1.3,
        reason: 'el cambio debe persistir en el repo',
      );
      expect(
        (await PrefsSettingsRepo(prefs).load()).textScale,
        1.3,
        reason: 'y en SharedPreferences',
      );
    });
  });

  group('AjustesScreen', () {
    Future<ProviderContainer> pumpAjustes(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Ajustes solo se alcanza tras onboarding: hay perfil local.
          initialProfileProvider.overrideWithValue(
            const ChildProfile(id: 'local', nickname: 'Sol'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: AjustesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('muestra modo calma, voz, legal y créditos', (tester) async {
      await pumpAjustes(tester);

      expect(find.text('Modo calma'), findsOneWidget);
      expect(find.text('Tamaño del texto'), findsOneWidget);
      expect(find.text('Velocidad de la voz'), findsOneWidget);
      expect(find.text('Tono de la voz'), findsOneWidget);

      // Créditos quedan bajo el fold: hay que hacer scroll.
      await tester.scrollUntilVisible(
        find.text('Pictogramas: Mulberry Symbols'),
        300,
      );
      await tester.pumpAndSettle();

      expect(find.text('Términos y condiciones'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.text('Pictogramas: Mulberry Symbols'), findsOneWidget);
      expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
    });

    testWidgets('el slider de tamaño de texto persiste', (tester) async {
      final container = await pumpAjustes(tester);

      await tester
          .drag(find.byType(Slider).first, const Offset(40, 0));
      await tester.pumpAndSettle();

      final scale =
          (await container.read(settingsProvider.future)).textScale;
      expect(scale, isNot(1.0));
    });

    testWidgets('el enlace legal abre el placeholder', (tester) async {
      await pumpAjustes(tester);

      await tester.scrollUntilVisible(
        find.text('Política de privacidad'),
        300,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Política de privacidad'));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar'), findsOneWidget);
    });

    testWidgets('si los ajustes fallan, los sliders de voz quedan inactivos',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Forzamos el estado de error (p.ej. storage roto).
          settingsProvider.overrideWith(
            () => throw StateError('storage roto'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: AjustesScreen())),
        ),
      );
      await tester.pumpAndSettle();

      final sliders = tester
          .widgetList<Slider>(find.byType(Slider))
          .toList();
      // Los dos sliders de voz siguen pintados pero no se pueden mover.
      expect(sliders, hasLength(2));
      expect(sliders.every((s) => s.onChanged == null), isTrue);
      expect(find.text('No se pudieron cargar los ajustes'), findsOneWidget);
      // La sección de recordatorios explica su estado en vez de
      // mostrar un interruptor que no funcionaría (revisión fase 1).
      expect(
        find.text('No se pueden cambiar los recordatorios ahora.'),
        findsOneWidget,
      );
      expect(find.text('Recordatorios de rutina'), findsNothing);
    });

    testWidgets('sección Tu avatar: elegir avatar lo persiste', (tester) async {
      final container = await pumpAjustes(tester);

      await tester.scrollUntilVisible(find.text('Tu avatar'), 300);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Gato'));
      await tester.pumpAndSettle();

      expect(container.read(profileProvider)?.avatarPicto, 'cat');
      expect(
        (await PrefsProfileRepo(
          container.read(sharedPreferencesProvider),
        ).currentProfile())?.avatarPicto,
        'cat',
        reason: 'la selección debe sobrevivir a un reinicio',
      );
    });
  });
}
