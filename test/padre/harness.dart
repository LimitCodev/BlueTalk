import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/gate/biometria.dart';
import 'package:bluetalk/features/padre/gate/pin_store.dart';
import 'package:bluetalk/features/padre/reloj.dart';

/// Instante fijo de todos los tests: jueves 13 de octubre de 2026, 10:00.
final DateTime ahoraFija = DateTime(2026, 10, 13, 10);

/// Reloj por defecto (sin [RelojPrueba]): siempre el instante fijo.
DateTime _relojFijo() => ahoraFija;

/// AssetBundle que lee del disco directamente.
///
/// `flutter test` solo responde el canal `flutter/assets` en el primer
/// testWidgets del archivo; así los tests quedan herméticos (mismo patrón
/// que `test/juegos/harness.dart` y `test/comunicador/harness.dart`).
class DiskAssetBundle extends AssetBundle {
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

/// Reloj falso: los tests avanzan 60 segundos de un golpe para el lockout.
class RelojPrueba {
  RelojPrueba([DateTime? inicio]) : ahora = inicio ?? ahoraFija;

  DateTime ahora;

  DateTime decir() => ahora;

  void avanzar(Duration duracion) => ahora = ahora.add(duracion);
}

/// Doble de biometría: `local_auth` no tiene canal de plataforma en tests.
class BiometriaPrueba implements Biometria {
  bool autenticarOk = false;
  int autenticaciones = 0;

  @override
  Future<bool> disponible() async => true;

  @override
  Future<bool> autenticar() async {
    autenticaciones++;
    return autenticarOk;
  }
}

/// Preferencias de prueba con la fecha de bloqueo ya calculada.
Future<SharedPreferences> prefsDePrueba({
  Map<String, Object> iniciales = const {},
}) async {
  SharedPreferences.setMockInitialValues(iniciales);
  return SharedPreferences.getInstance();
}

/// Overrides de DI de la zona de adultos: seeds del disco, prefs y reloj.
List<Object> overridesDePadre(
  SharedPreferences prefs, {
  RelojPrueba? reloj,
  BiometriaPrueba? biometria,
}) =>
    [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedStoreProvider.overrideWithValue(
        SeedStore(
          (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
        ),
      ),
      relojProvider.overrideWithValue(reloj?.decir ?? _relojFijo),
      if (biometria != null)
        biometriaProvider.overrideWithValue(biometria),
    ];

/// Bombea una pantalla suelta con seeds del disco y prefs locales.
Future<ProviderContainer> pumpPadre(
  WidgetTester tester, {
  required Widget home,
  required List<Object> overrides,
}) async {
  final container = ProviderContainer(overrides: overrides.cast());
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: MaterialApp(home: home),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Sembrar eventos de uso (comunicador, juegos…) para el dashboard.
Future<void> sembrarEventos(
  SharedPreferences prefs,
  List<UsageEvent> eventos,
) async {
  final repo = PrefsUsageRepo(prefs);
  for (final evento in eventos) {
    await repo.record(evento);
  }
}

/// Evento de prueba con fecha relativa a [desde].
UsageEvent evento(
  String type, {
  DateTime? creado,
  Map<String, dynamic> data = const {},
  String? id,
}) =>
    UsageEvent(
      id: id ?? '${type}_${creado ?? ahoraFija.microsecondsSinceEpoch}',
      type: type,
      createdAt: creado ?? ahoraFija,
      data: data,
    );

/// Crea un PIN directamente en prefs (para arrancar en fase de petición).
///
/// Para el pin de uso común ('1234') se siembra una huella **precalculada**
/// (PBKDF2-HMAC-SHA256, sal fija) en vez de derivarla: la PBKDF2 de
/// `cryptography` cede con timers, y dentro de un cuerpo `testWidgets`
/// (FakeAsync) un `await` del hashing sin pumps concurrentes es un
/// deadlock — por eso los tests que hacían `await crearPinDePrueba(...)`
/// colgaban para siempre. Cualquier otro pin sí pasa por el hash real
/// (solo aplica fuera de FakeAsync o con bombeo concurrente).
Future<void> crearPinDePrueba(SharedPreferences prefs, {String pin = '1234'}) async {
  if (pin != '1234') {
    await PinStore(prefs, ahora: () => ahoraFija).crear(pin);
    return;
  }
  await prefs.setString(
    PinStore.claveSalt,
    '4c2c421d3df371b269aa7772ee5336d3',
  );
  await prefs.setString(
    PinStore.claveHash,
    '6ef6f3446c5b72722a63c08103f96e5bf12b9b3263dcab9e547c734b14918fcb',
  );
  await prefs.remove(PinStore.claveIntentos);
  await prefs.remove(PinStore.claveBloqueo);
}

/// Regla de aceptación legal ya registrada (para arrancar tras el gate).
String aceptacionLegalDePrueba() =>
    '{"version":"1.0.0","fecha":${ahoraFija.millisecondsSinceEpoch},'
    '"consentimientoPadre":true}';
