import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/app/router.dart';
import 'package:bluetalk/app/atras_shell.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/comunicador_controller.dart';
import 'package:bluetalk/features/comunicador/comunicador_screen.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/inicio/inicio_screen.dart';
import 'package:bluetalk/features/juegos/artista/artista_screen.dart';
import 'package:bluetalk/features/juegos/juegos_screen.dart';
import 'package:bluetalk/features/padre/gate/gate_controller.dart';
import 'package:bluetalk/features/padre/legal/legal_screen.dart';
import 'package:bluetalk/features/padre/padre_controller.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';
import 'package:bluetalk/features/rutinas/rutinas_controller.dart';

import '../comunicador/dobles.dart';
import '../padre/harness.dart';

Future<SharedPreferences> _givenPrefs() => _givenPrefsCon({});

Future<SharedPreferences> _givenPrefsCon(Map<String, Object> values) async {
  // La guía de la mascota (plan 14B) se prueba en test/guia/.
  SharedPreferences.setMockInitialValues({'guia_vista': true, ...values});
  return SharedPreferences.getInstance();
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  SharedPreferences prefs, {
  ChildProfile? profile,
  // Gancho kiosko (plan 13 P1 / plan 12): false = el Atrás no sale de
  // la app desde Comunicar. (riverpod 3 no exporta el tipo Override,
  // por eso no se pasa una lista de overrides.)
  bool saleConAtras = true,
  // Con perfil, la app arranca en el menú (plan 14A). Casi todos los
  // tests empiezan dentro de Comunicar, como antes del menú.
  bool enComunicar = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (!saleConAtras)
          saleConAtrasProvider.overrideWithValue(false),
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (profile != null) initialProfileProvider.overrideWithValue(profile),
        // El shell aloja el comunicador real: seeds leídas del disco y TTS
        // falso para que el test sea hermético (el canal de assets de
        // flutter test solo responde en el primer testWidgets del archivo).
        ttsSpeakerProvider.overrideWithValue(FakeTtsSpeaker()),
        seedStoreProvider.overrideWithValue(
          SeedStore(
            (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
          ),
        ),
        // La PBKDF2 real corre en un isolate y no completa dentro de
        // testWidgets (ver harness.dart del gate).
        derivadorPinProvider.overrideWithValue(const DerivadorPinPrueba()),
      ],
      child: const BlueTalkApp(),
    ),
  );
  final container =
      ProviderScope.containerOf(tester.element(find.byType(BlueTalkApp)));
  if (profile != null && enComunicar) {
    container.read(routerProvider).go('/home/comunicar');
    await tester.pumpAndSettle();
  }
  return container;
}

/// Completa el onboarding escribiendo un apodo (sin PII).
Future<void> _completarOnboarding(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Sol');
  // El botón se habilita en el rebuild posterior a onChanged.
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
  await tester.pumpAndSettle();
}

/// Consentimiento legal + creación de PIN para llegar al panel del padre.
Future<void> _entrarAlPanelPadre(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(routerProvider).go('/padre');
  await tester.pumpAndSettle();
  expect(find.byType(LegalScreen), findsOneWidget);

  // Consentimiento parental y aceptación (la legal es la primera vez).
  await tester.scrollUntilVisible(find.byType(CheckboxListTile), 300);
  await tester.tap(find.byType(CheckboxListTile));
  await tester.pump();
  final aceptar = find.widgetWithText(FilledButton, 'Aceptar y continuar');
  await tester.scrollUntilVisible(aceptar, 300);
  await tester.tap(aceptar);
  await tester.pumpAndSettle();

  // Se crea un PIN de prueba para llegar al panel.
  await tester.enterText(find.byType(TextField), '123456');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '123456');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
  await tester.pumpAndSettle();
  expect(find.byType(NavigationBar), findsOneWidget, reason: 'panel');
}

void main() {
  testWidgets('onboarding: pide apodo y entra al menú', (tester) async {
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

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('¡Hola, Sol! 👋'), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsNothing);

    // El perfil quedó guardado localmente.
    final saved = await PrefsProfileRepo(prefs).currentProfile();
    expect(saved, isNotNull);
    expect(saved!.nickname, 'Sol');
  });

  testWidgets('con perfil guardado arranca directo en el menú', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
      enComunicar: false,
    );

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('¿Cómo te llamas?'), findsNothing);
  });

  testWidgets('el apodo es opcional: se puede entrar sin él', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    await tester.tap(find.text('Entrar sin apodo'));
    await tester.pumpAndSettle();

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('¡Hola! 👋'), findsOneWidget);
    final saved = await PrefsProfileRepo(prefs).currentProfile();
    expect(saved, isNotNull, reason: 'aunque sin apodo sí se crea el perfil');
  });

  testWidgets(
    'las pestañas navegan y el botón del shell activa el modo calma',
    (tester) async {
      final prefs = await _givenPrefs();
      final container = await _pumpApp(tester, prefs);

      await _completarOnboarding(tester);
      container.read(routerProvider).go('/home/comunicar');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.byType(CalmModeToggle), findsOneWidget);

      await tester.tap(find.byIcon(Icons.contrast));
      await tester.pumpAndSettle();
      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(prefs.getBool(CalmModeController.prefKey), isTrue);
    },
  );

  testWidgets('ruta /padre muestra la legal la primera vez', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    container.read(routerProvider).go('/padre');
    await tester.pumpAndSettle();

    // Sin legal aceptada: vista legal dentro del PadreScreen (AppBar + botón).
    expect(find.text('Modo padre'), findsOneWidget);
    expect(find.byType(LegalScreen), findsOneWidget);
  });

  testWidgets('modo calma: las rutas cambian con duración cero', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    await container.read(calmModeProvider.notifier).set(true);
    await tester.pump();

    container.read(routerProvider).go('/home/aprender');
    await tester.pumpAndSettle();

    final calmRoute = ModalRoute.of(tester.element(find.byType(JuegosScreen)));
    expect(calmRoute, isNotNull);
    expect(calmRoute!.transitionDuration, Duration.zero);

    // Sin modo calma la transición normal sí existe.
    await container.read(calmModeProvider.notifier).set(false);
    await tester.pump();
    container.read(routerProvider).go('/home/rutinas');
    await tester.pumpAndSettle();

    final normalRoute = ModalRoute.of(tester.element(find.text('Mi horario')));
    expect(normalRoute!.transitionDuration, isNot(Duration.zero));
  });

  testWidgets('juegos bloqueados por un adulto muestran el aviso suave', (
    tester,
  ) async {
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

  testWidgets('tiempo de juegos agotado muestra el aviso con salida', (
    tester,
  ) async {
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

    expect(find.text('El tiempo de juegos de hoy terminó.'), findsOneWidget);
    expect(find.byType(JuegosScreen), findsNothing);
  });

  testWidgets('colegio bloqueado por un adulto muestra el aviso y vuelve', (
    tester,
  ) async {
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

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Mi horario'), findsOneWidget);
  });

  // ── Plan 13 P1: el botón Atrás dentro de la app ────────────────────
  // Una prueba por cada fila de la tabla del plan, con handlePopRoute().

  testWidgets('P1 fila 1: Atrás dentro de un juego vuelve a Aprender', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    await tester.tap(find.text('Aprender'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    expect(find.byType(ArtistaScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(ArtistaScreen), findsNothing);
    expect(find.text('Memoria'), findsOneWidget, reason: 'está en la lista');
  });

  testWidgets('Atrás en una vista de Rutinas vuelve a la lista de Rutinas', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    await tester.tap(find.text('Rutinas'));
    await tester.pumpAndSettle();
    container.read(rutinasProvider.notifier).abrir(RutinaVista.horario);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(container.read(rutinasProvider), RutinaVista.inicio);
    expect(find.byType(ComunicadorScreen), findsNothing);
  });

  testWidgets(
    'Atrás en Aprender, Rutinas o Ajustes va al menú (plan 14 §2)',
    (tester) async {
      final prefs = await _givenPrefs();
      final container = await _pumpApp(
        tester,
        prefs,
        profile: const ChildProfile(id: 'local', nickname: 'Sol'),
      );

      for (final pestana in ['Aprender', 'Rutinas', 'Ajustes']) {
        container.read(routerProvider).go('/home/comunicar');
        await tester.pumpAndSettle();
        await tester.tap(find.text(pestana));
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(
          find.byType(InicioScreen),
          findsOneWidget,
          reason: 'Atrás desde $pestana debe volver al menú',
        );
      }
    },
  );

  testWidgets('Atrás en Comunicar va al menú y en el menú sale de la app', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    final llamadas = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        llamadas.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Desde Comunicar se vuelve al menú, sin salir (plan 14 §2)…
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(llamadas.any((c) => c.method == 'SystemNavigator.pop'), isFalse);

    // …y desde el menú se le pide al sistema cerrar la app.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      llamadas.any((llamada) => llamada.method == 'SystemNavigator.pop'),
      isTrue,
    );
  });

  testWidgets('Atrás dentro de una categoría vuelve al tablero y no sale', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    final llamadas = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        llamadas.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final comunicador = container.read(comunicadorProvider.notifier);
    comunicador.openCategory('emociones');
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(container.read(comunicadorProvider).categoryId, isNull);
    expect(llamadas.any((c) => c.method == 'SystemNavigator.pop'), isFalse);
  });

  testWidgets('P1 fila 4: Atrás en la zona de padre: subpantalla al panel, '
      'panel al menú', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    await _entrarAlPanelPadre(tester, container);

    // Cerrar sesión deja el gate en «Escribe tu código». (El candado del
    // encabezado se quitó en la mejora del modo padre; el cierre se
    // dispara desde el controlador, igual que al pulsar la X.)
    container.read(padreProvider.notifier).cerrarSesion();
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu código'), findsOneWidget);

    // Subpantalla empujada (recuperación del PIN).
    await tester.ensureVisible(
      find.widgetWithText(TextButton, '¿Olvidaste el código?'),
    );
    await tester.tap(find.widgetWithText(TextButton, '¿Olvidaste el código?'));
    await tester.pumpAndSettle();

    // Atrás: la subpantalla se cierra y se vuelve al gate (panel).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu código'), findsOneWidget);

    // Atrás otra vez: del panel al menú principal (plan 14 §2).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InicioScreen), findsOneWidget);
  });

  testWidgets('P1 fila 4: Atrás en una pestaña del padre vuelve al panel, '
      'no cierra sesión', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    await _entrarAlPanelPadre(tester, container);

    // Pestaña Control (etiqueta propia de la barra de navegación).
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Control'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Límite diario de juegos'), findsOneWidget);

    // Atrás: vuelve al panel (Resumen); no cierra sesión ni sale a Ajustes.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byType(NavigationBar),
      findsOneWidget,
      reason: 'sigue en el modo padre',
    );
    expect(find.text('Límite diario de juegos'), findsNothing);

    // Atrás desde el panel: sale al menú (misma lógica de «Salir»).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InicioScreen), findsOneWidget);
  });

  testWidgets('P1 fila 5: Atrás cierra un diálogo sin salir de la pantalla', (
    tester,
  ) async {
    final prefs = await _givenPrefs();
    await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    final privacidad = find.text('Política de privacidad');
    await tester.scrollUntilVisible(privacidad, 300);
    // La lista creció con la tipografía de la web: asegurar que la fila
    // quede dentro del área visible antes de tocarla.
    await tester.ensureVisible(privacidad);
    await tester.pumpAndSettle();
    await tester.tap(privacidad);
    await tester.pumpAndSettle();
    expect(find.text('1. Responsable del tratamiento'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.text('1. Responsable del tratamiento'),
      findsNothing,
      reason: 'Atrás cierra la política',
    );
    expect(
      find.text('Zona de adultos'),
      findsOneWidget,
      reason: 'sigue dentro de Ajustes',
    );
  });

  testWidgets(
    'P1 gancho kiosko: con saleConAtras=false, Atrás en el menú no sale',
    (tester) async {
      final prefs = await _givenPrefs();
      await _pumpApp(
        tester,
        prefs,
        profile: const ChildProfile(id: 'local', nickname: 'Sol'),
        saleConAtras: false,
        enComunicar: false,
      );
      final llamadas = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          llamadas.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        find.byType(InicioScreen),
        findsOneWidget,
        reason: 'el niño no sale de BlueTalk con el botón Atrás',
      );
      expect(
        llamadas.any((llamada) => llamada.method == 'SystemNavigator.pop'),
        isFalse,
        reason: 'el gancho kiosko anula la salida',
      );
    },
  );

  // ── Plan 13 P6.1: fallos que la gente sufrió en otras apps ────────────

  testWidgets(
      'P6.1: con el teclado abierto, Comenzar sigue visible y avanza',
      (tester) async {
    addTearDown(tester.view.reset);
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    // Teclado virtual abierto (300 dp sobre 600 dp de pantalla).
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Sol');
    await tester.pump();

    // La pantalla no se congela ni se desborda y el botón principal se
    // puede tocar con el teclado abierto (reseña: no se podía avanzar).
    await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
    await tester.pumpAndSettle();

    expect(
      find.byType(InicioScreen),
      findsOneWidget,
      reason: 'se avanzó al menú con el teclado abierto',
    );
  });

  testWidgets('P6.1: la voz nunca suena sola al abrir la app', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(
      tester,
      prefs,
      profile: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    await tester.pumpAndSettle();

    final tts = container.read(ttsSpeakerProvider) as FakeTtsSpeaker;
    expect(
      tts.spoken,
      isEmpty,
      reason: 'ninguna voz automática al iniciar (plan 00, no negociable)',
    );
  });
}
