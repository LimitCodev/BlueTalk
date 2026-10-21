import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/gate/almacen_pin.dart';
import 'package:bluetalk/features/padre/gate/pin_store.dart';

import 'harness.dart';

/// Keystore falso: `write/readAll/delete` sobre un mapa, y marca si alguna
/// vez se intentó escribir el PIN en claro por el camino equivocado.
class _KeystoreFalso implements FlutterSecureStorage {
  _KeystoreFalso({this.conKeystore = true});

  final Map<String, String> datos = {};
  bool conKeystore;
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
    datos.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Huellas sembradas en preferencias, como estaban antes de esta versión.
  Future<(SharedPreferences, _KeystoreFalso, AlmacenPin)> conHuellaVieja() async {
    final prefs = await prefsDePrueba();
    await prefs.setString(PinStore.claveSalt, '4c2c421d3df371b269aa7772ee5336d3');
    await prefs.setString(
      PinStore.claveHash,
      '6ef6f3446c5b72722a63c08103f96e5bf12b9b3263dcab9e547c734b14918fcb',
    );
    await prefs.setInt(PinStore.claveLongitud, 4);
    await prefs.setInt(PinStore.claveIteraciones, 10000);
    final keystore = _KeystoreFalso();
    return (prefs, keystore, AlmacenPin(prefs: prefs, sistema: keystore));
  }

  group('migración al keystore cifrado (encargo §3.1)', () {
    test('las huellas que estaban en preferencias pasan al keystore', () async {
      final (prefs, keystore, almacen) = await conHuellaVieja();

      await almacen.cargar();

      expect(keystore.datos[PinStore.claveHash], isNotNull);
      expect(keystore.datos[PinStore.claveSalt], isNotNull);
      expect(
        prefs.getString(PinStore.claveHash),
        isNull,
        reason: 'ya no debe quedar en texto plano en preferencias',
      );
      expect(prefs.getString(PinStore.claveSalt), isNull);
      expect(almacen.cifrado, isTrue);
    });

    test('lo que no es secreto se queda donde estaba', () async {
      final (prefs, _, almacen) = await conHuellaVieja();

      await almacen.cargar();

      expect(prefs.getInt(PinStore.claveLongitud), 4);
      expect(prefs.getInt(PinStore.claveIteraciones), 10000);
      expect(
        AlmacenPin.clavesSecretas,
        isNot(contains(PinStore.claveLongitud)),
        reason: 'la longitud y las iteraciones no son secretos',
      );
    });

    test('el PIN antiguo sigue abriendo tras migrar', () async {
      final (prefs, _, almacen) = await conHuellaVieja();
      await almacen.cargar();
      final store = PinStore(
        prefs,
        almacen: almacen,
        ahora: () => ahoraFija,
        derivador: const DerivadorPinPrueba(),
      );

      expect(await store.verificar('1234'), VerificacionPin.correcto);
    });

    test('si el keystore falla no se migra ni se pierde el acceso', () async {
      final prefs = await prefsDePrueba();
      await prefs.setString(PinStore.claveSalt, '4c2c421d3df371b269aa7772ee5336d3');
      await prefs.setString(
        PinStore.claveHash,
        '6ef6f3446c5b72722a63c08103f96e5bf12b9b3263dcab9e547c734b14918fcb',
      );
      await prefs.setInt(PinStore.claveLongitud, 4);
      await prefs.setInt(PinStore.claveIteraciones, 10000);
      final almacen = AlmacenPin(
        prefs: prefs,
        sistema: _KeystoreFalso(conKeystore: false),
      );

      await almacen.cargar();

      expect(prefs.getString(PinStore.claveHash), isNotNull,
          reason: 'sin keystore no se borra nada');
      expect(almacen.cifrado, isFalse, reason: 'hay que poder decirlo');
      expect(almacen.tiene(PinStore.claveHash), isTrue);

      final store = PinStore(
        prefs,
        almacen: almacen,
        ahora: () => ahoraFija,
        derivador: const DerivadorPinPrueba(),
      );
      expect(await store.verificar('1234'), VerificacionPin.correcto);
    });

    test('una huella nueva se escribe cifrada y sale de preferencias', () async {
      final prefs = await prefsDePrueba();
      final keystore = _KeystoreFalso();
      final almacen = AlmacenPin(prefs: prefs, sistema: keystore);
      await almacen.cargar();
      final store = PinStore(
        prefs,
        almacen: almacen,
        ahora: () => ahoraFija,
        derivador: const DerivadorPinPrueba(),
      );

      await store.crear('987654');

      expect(keystore.escrituras, greaterThan(0));
      expect(keystore.datos[PinStore.claveHash], isNotNull);
      expect(prefs.getString(PinStore.claveHash), isNull);
      expect(prefs.getString(PinStore.claveSalt), isNull);
      expect(almacen.cifrado, isTrue);
    });

    test('el PIN en claro no aparece en ningún almacén', () async {
      final prefs = await prefsDePrueba();
      final keystore = _KeystoreFalso();
      final almacen = AlmacenPin(prefs: prefs, sistema: keystore);
      await almacen.cargar();
      final store = PinStore(
        prefs,
        almacen: almacen,
        ahora: () => ahoraFija,
        derivador: const DerivadorPinPrueba(),
      );

      await store.crear('445566');

      final todo = <String>[
        ...prefs.getKeys(),
        ...keystore.datos.keys,
      ];
      for (final clave in todo) {
        final valor = keystore.datos[clave] ?? prefs.get(clave)?.toString();
        expect(valor, isNot('445566'), reason: clave);
      }
    });
  });
}
