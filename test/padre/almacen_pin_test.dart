import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/almacen/almacen_local.dart';
import 'package:bluetalk/features/padre/gate/almacen_pin.dart';
import 'package:bluetalk/features/padre/gate/pin_store.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Huellas sembradas en preferencias, como estaban antes de esta versión.
  Future<(SharedPreferences, KeystorePrueba, AlmacenPin)> conHuellaVieja() async {
    final prefs = await prefsDePrueba();
    await prefs.setString(PinStore.claveSalt, '4c2c421d3df371b269aa7772ee5336d3');
    await prefs.setString(
      PinStore.claveHash,
      '6ef6f3446c5b72722a63c08103f96e5bf12b9b3263dcab9e547c734b14918fcb',
    );
    await prefs.setInt(PinStore.claveLongitud, 4);
    await prefs.setInt(PinStore.claveIteraciones, 10000);
    final keystore = KeystorePrueba();
    return (prefs, keystore, AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore));
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
        AlmacenPrefs(prefs),
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
        prefs: AlmacenPrefs(prefs),
        sistema: KeystorePrueba(conKeystore: false),
      );

      await almacen.cargar();

      expect(prefs.getString(PinStore.claveHash), isNotNull,
          reason: 'sin keystore no se borra nada');
      expect(almacen.cifrado, isFalse, reason: 'hay que poder decirlo');
      expect(almacen.tiene(PinStore.claveHash), isTrue);

      final store = PinStore(
        AlmacenPrefs(prefs),
        almacen: almacen,
        ahora: () => ahoraFija,
        derivador: const DerivadorPinPrueba(),
      );
      expect(await store.verificar('1234'), VerificacionPin.correcto);
    });

    test('una huella nueva se escribe cifrada y sale de preferencias', () async {
      final prefs = await prefsDePrueba();
      final keystore = KeystorePrueba();
      final almacen = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await almacen.cargar();
      final store = PinStore(
        AlmacenPrefs(prefs),
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
      final keystore = KeystorePrueba();
      final almacen = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await almacen.cargar();
      final store = PinStore(
        AlmacenPrefs(prefs),
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

  group('borrado total de las huellas (revisión de la fase 3a)', () {
    test('las borra del keystore, de preferencias y de la caché', () async {
      final (prefs, keystore, almacen) = await conHuellaVieja();
      await almacen.cargar();
      // Precondición: la huella vive en el keystore, no en preferencias.
      expect(keystore.datos[PinStore.claveHash], isNotNull);

      final hecho = await almacen.borrarSecretas();

      expect(hecho, isTrue);
      for (final clave in AlmacenPin.clavesSecretas) {
        expect(keystore.datos.containsKey(clave), isFalse, reason: clave);
        expect(prefs.containsKey(clave), isFalse, reason: clave);
        expect(almacen.tiene(clave), isFalse, reason: clave);
        expect(almacen.leer(clave), isNull, reason: clave);
      }
    });

    test(
        'si el keystore no deja borrar, no se declara hecho ni se toca nada',
        () async {
      final (prefs, keystore, almacen) = await conHuellaVieja();
      await almacen.cargar();
      keystore.borradoFallido = true;

      final hecho = await almacen.borrarSecretas();

      expect(hecho, isFalse,
          reason: 'un borrado a medias no puede presentarse como hecho');
      expect(keystore.datos[PinStore.claveHash], isNotNull,
          reason: 'la huella sigue donde estaba: nada quedó a medias');
      expect(almacen.tiene(PinStore.claveHash), isTrue);
      expect(almacen.leer(PinStore.claveHash), isNotNull,
          reason: 'el PIN que había sigue validando hasta que se resuelva');
      // Preferencias no se tocaron: los datos del modo padre siguen.
      expect(prefs.getInt(PinStore.claveLongitud), 4);
    });

    test('sin keystore operativo se borra de preferencias', () async {
      final prefs = await prefsDePrueba();
      await prefs.setString(PinStore.claveSalt, '4c2c421d3df371b269aa7772ee5336d3');
      await prefs.setString(PinStore.claveHash, '6ef6f3446c');
      final almacen = AlmacenPin(
        prefs: AlmacenPrefs(prefs),
        sistema: KeystorePrueba(conKeystore: false),
      );

      final hecho = await almacen.borrarSecretas();

      expect(hecho, isTrue);
      expect(prefs.containsKey(PinStore.claveHash), isFalse);
      expect(prefs.containsKey(PinStore.claveSalt), isFalse);
      expect(almacen.tiene(PinStore.claveHash), isFalse);
    });
  });

  group('keystore que lee pero no escribe (revisión 2 de la fase 3a)', () {
    test('no manda en las lecturas ni en lo que se muestra', () async {
      final prefs = await prefsDePrueba();
      final keystore = KeystorePrueba();
      await keystore.write(key: PinStore.claveHash, value: 'huella-vieja');
      keystore.escrituraFallida = true;

      final almacen = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await almacen.cargar();

      expect(almacen.leer(PinStore.claveHash), isNull,
          reason: 'una huella de un keystore que no escribe no se usa');
      expect(almacen.tiene(PinStore.claveHash), isFalse);
      expect(almacen.cifrado, isFalse,
          reason: 'en pantalla no se anuncia cifrado donde no se puede escribir');
    });

    test('el borrado total aun así va al keystore y no miente', () async {
      final prefs = await prefsDePrueba();
      final keystore = KeystorePrueba();
      await keystore.write(key: PinStore.claveHash, value: 'huella-vieja');
      keystore.escrituraFallida = true;

      final almacen = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await almacen.cargar();

      // Si el borrado del keystore funciona, la huella vieja sale de ahí.
      expect(await almacen.borrarSecretas(), isTrue);
      expect(keystore.datos, isEmpty,
          reason: 'estaba ahí y se pudo borrar: de ahí tenía que salir');

      // Y si además no deja borrar, no se declara hecho nada.
      keystore.escrituraFallida = false;
      await keystore.write(key: PinStore.claveHash, value: 'otra-vieja');
      keystore.escrituraFallida = true;
      keystore.borradoFallido = true;
      final segunda = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await segunda.cargar();

      expect(await segunda.borrarSecretas(), isFalse);
      expect(keystore.datos[PinStore.claveHash], isNotNull);
      expect(await segunda.borrar(PinStore.claveHash), isFalse);
      expect(prefs.containsKey(PinStore.claveHash), isFalse,
          reason: 'en preferencias no había nada: solo estaba en el keystore');
    });

    test('borrar una clave devuelve false sin tocar nada si falla', () async {
      final prefs = await prefsDePrueba();
      await prefs.setString(PinStore.claveHash, '6ef6f3446c');
      final keystore = KeystorePrueba();
      await keystore.write(key: PinStore.claveHash, value: 'huella-en-keystore');
      final almacen = AlmacenPin(prefs: AlmacenPrefs(prefs), sistema: keystore);
      await almacen.cargar();
      keystore.borradoFallido = true;

      final hecho = await almacen.borrar(PinStore.claveHash);

      expect(hecho, isFalse);
      expect(prefs.getString(PinStore.claveHash), '6ef6f3446c',
          reason: 'nada se borra de preferencias si sigue viva en el keystore');
      expect(keystore.datos[PinStore.claveHash], 'huella-en-keystore');
      expect(almacen.tiene(PinStore.claveHash), isTrue,
          reason: 'el PIN que había sigue abriendo hasta que se pueda borrar');
    });
  });
}
