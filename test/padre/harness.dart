import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/local/mock_repos.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/gate/biometria.dart';
import 'package:bluetalk/features/padre/gate/almacen_pin.dart';
import 'package:bluetalk/features/padre/permisos/permiso_model.dart';
import 'package:bluetalk/features/padre/permisos/permisos_controller.dart';
import 'package:bluetalk/features/padre/permisos/permisos_gateway.dart';
import 'package:bluetalk/features/padre/gate/gate_controller.dart';
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

/// Keystore falso: `write/readAll/delete` sobre un mapa, y marca si alguna
/// vez se intentó escribir el PIN en claro por el camino equivocado.
///
/// [borradoFallido] emula un keystore que no deja borrar, para comprobar
/// que el borrado total de datos no se declara hecho si no lo está.
class KeystorePrueba implements FlutterSecureStorage {
  KeystorePrueba({this.conKeystore = true});

  final Map<String, String> datos = {};
  bool conKeystore;
  bool borradoFallido = false;
  int escrituras = 0;

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (!conKeystore) throw MissingPluginException('sin keystore');
    return Map.of(datos);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (!conKeystore) throw MissingPluginException('sin keystore');
    escrituras++;
    if (value == null) {
      datos.remove(key);
    } else {
      datos[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (!conKeystore) throw MissingPluginException('sin keystore');
    if (borradoFallido) throw Exception('keystore que no deja borrar');
    datos.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

/// Canal de permisos que siempre dice «concedido», para que el
/// diagnóstico del asistente termine en los tests.
class _PermisosDePrueba implements PermisosGateway {
  const _PermisosDePrueba();

  @override
  Future<EstadoPermiso> estadoAvisos() async => EstadoPermiso.concedido;

  @override
  Future<EstadoPermiso> estadoBateria() async => EstadoPermiso.concedido;

  @override
  Future<bool> pedirAvisos() async => true;

  @override
  Future<bool> pedirBateria() async => true;
}

/// PBKDF2 en la zona del test: misma huella que [DerivadorPinAislamiento],
/// pero sin isolate. `Isolate.run` no completa dentro de `testWidgets`
/// (FakeAsync no procesa mensajes de isolates; ver plan 12 §0.2), y la
/// PBKDF2 cede con timers que solo avanzan con pumps — por eso los tests de
/// widget la bombean con `pumpAndSettle` en lugar de esperarla.
class DerivadorPinPrueba implements DerivadorPin {
  const DerivadorPinPrueba();

  @override
  Future<List<int>> derivar(String pin, List<int> salt, int iteraciones) async {
    final algoritmo = Pbkdf2.hmacSha256(iterations: iteraciones, bits: 256);
    final clave = await algoritmo.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return clave.extractBytes();
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
  DerivadorPin? derivador,
  PermisosGateway? permisos,
}) =>
    [
      sharedPreferencesProvider.overrideWithValue(prefs),
      seedStoreProvider.overrideWithValue(
        SeedStore(
          (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
        ),
      ),
      relojProvider.overrideWithValue(reloj?.decir ?? _relojFijo),
      // La PBKDF2 real corre en un isolate, que no completa dentro de
      // testWidgets (ver [DerivadorPinPrueba]).
      derivadorPinProvider.overrideWithValue(
        derivador ?? const DerivadorPinPrueba(),
      ),
      if (biometria != null)
        biometriaProvider.overrideWithValue(biometria),
      // Doble del canal nativo de permisos: en `flutter test` el canal no
      // contesta y el diagnóstico se quedaría sin resolver. Todo concedido
      // es lo inofensivo de esta casa: no bloquea el modo padre.
      permisosGatewayProvider.overrideWithValue(
        permisos ?? const _PermisosDePrueba(),
      ),
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
/// (PBKDF2-HMAC-SHA256, sal fija, 10.000 iteraciones = esquema actual) en
/// vez de derivarla: la PBKDF2 de `cryptography` cede con timers, y dentro
/// de un cuerpo `testWidgets` (FakeAsync) un `await` del hashing sin pumps
/// concurrentes es un deadlock — por eso los tests que hacían
/// `await crearPinDePrueba(...)` colgaban para siempre. La semilla describe
/// un PIN de 4 dígitos del esquema antiguo (`padre_pin_len` = 4) y declara
/// sus parámetros (`padre_pin_iter` = 10.000) para que no se re-hashee al
/// primer acceso. Cualquier otro pin sí pasa por el hash real con
/// [DerivadorPinPrueba] (solo aplica fuera de FakeAsync o con bombeo
/// concurrente).
Future<void> crearPinDePrueba(SharedPreferences prefs, {String pin = '1234'}) async {
  if (pin != '1234') {
    await PinStore(
      prefs,
      almacen: AlmacenPin(prefs: prefs),
      ahora: () => ahoraFija,
      derivador: const DerivadorPinPrueba(),
    ).crear(pin);
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
  await prefs.setInt(PinStore.claveLongitud, 4);
  await prefs.setInt(PinStore.claveIteraciones, 10000);
  await prefs.remove(PinStore.claveIntentos);
  await prefs.remove(PinStore.claveBloqueo);
  await prefs.remove(PinStore.claveBloqueoDesde);
  await prefs.remove(PinStore.claveNivel);
}

/// Semilla de código de recuperación con hash precalculado (mismo motivo que
/// [crearPinDePrueba]: nada de PBKDF2 con await dentro de FakeAsync).
///
/// Código fijo de prueba `ABCD2345` (dentro del alfabeto sin I/O/0/1), sal
/// fija `0011…eeff` y 10.000 iteraciones; el hash se derivó con la misma
/// librería `cryptography` fuera de los tests.
Future<void> sembrarRecuperacionDePrueba(SharedPreferences prefs) async {
  await prefs.setString(
    PinStore.claveRecupSalt,
    '00112233445566778899aabbccddeeff',
  );
  await prefs.setString(
    PinStore.claveRecupHash,
    'd7d47a2aacccca9117604f5b8388932eadebc9c5c33818c48258ec11919d1b58',
  );
  await prefs.setInt(PinStore.claveRecupIter, 10000);
}

/// Regla de aceptación legal ya registrada (para arrancar tras el gate).
String aceptacionLegalDePrueba() =>
    '{"version":"1.1.0","fecha":${ahoraFija.millisecondsSinceEpoch},'
    '"consentimientoPadre":true}';
