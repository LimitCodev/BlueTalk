import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/features/comunicador/comunicador_screen.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';

import 'dobles.dart';

/// AssetBundle que lee del disco directamente.
///
/// `flutter test` solo responde el canal `flutter/assets` en el primer
/// testWidgets del archivo; así los tests quedan herméticos y rápidos.
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

/// Bombea el comunicador con seeds leídos del disco y TTS falso.
Future<ProviderContainer> pumpComunicador(
  WidgetTester tester, {
  FakeTtsSpeaker? tts,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      ttsSpeakerProvider.overrideWithValue(tts ?? FakeTtsSpeaker()),
      seedStoreProvider.overrideWithValue(
        SeedStore(
          (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const MaterialApp(
          home: Scaffold(body: ComunicadorScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Abre una categoría tocando su nombre en la rejilla del inicio.
Future<void> abrirCategoria(WidgetTester tester, String nombre) async {
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
}
