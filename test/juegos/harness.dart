import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/features/juegos/juegos_screen.dart';

/// AssetBundle que lee del disco directamente.
///
/// `flutter test` solo responde el canal `flutter/assets` en el primer
/// testWidgets del archivo; así los tests quedan herméticos y rápidos
/// (harness probado por el agente aac-comunicador).
class DiskAssetBundle extends AssetBundle {
  DiskAssetBundle();

  @override
  Future<ByteData> load(String key) {
    final bytes = File(key).readAsBytesSync();
    return SynchronousFuture<ByteData>(
      ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture<String>(File(key).readAsStringSync());
}

/// Preferencias de prueba (sin reiniciar, para verificar persistencia
/// dentro del mismo test).
Future<SharedPreferences> prefsDePrueba() async {
  return SharedPreferences.getInstance();
}

/// Overrides de DI para tests: seeds del disco y prefs de prueba.
List<Object> overridesDeJuegos(SharedPreferences prefs) => [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedStoreProvider.overrideWithValue(
        SeedStore(
          (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
        ),
      ),
    ];

/// Bombea la pestaña de juegos con seeds del disco y preferencias locales.
///
/// Con [resetPrefs] en false se reutiliza la instancia de preferencias
/// anterior (para verificar persistencia dentro del mismo test).
/// [modoCalma] envuelve la app en `MediaQuery.disableAnimations`, igual
/// que la raíz real en Modo calma (plan 00 §4).
Future<ProviderContainer> pumpJuegos(
  WidgetTester tester, {
  bool resetPrefs = true,
  bool modoCalma = false,
}) async {
  if (resetPrefs) SharedPreferences.setMockInitialValues({});
  final prefs = await prefsDePrueba();
  final container = ProviderContainer(
    overrides: overridesDeJuegos(prefs).cast(),
  );
  addTearDown(container.dispose);

  // El builder corre por debajo del MediaQuery propio de MaterialApp,
  // igual que la raíz real de la app (plan 00 §4).
  final Widget app = MaterialApp(
    home: const Scaffold(body: JuegosScreen()),
    builder: modoCalma
        ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
        : null,
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: app,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
