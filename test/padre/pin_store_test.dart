import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/padre/gate/pin_store.dart';

import 'harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RelojPrueba reloj;

  Future<PinStore> store(SharedPreferences prefs) async =>
      PinStore(prefs, ahora: reloj.decir);

  setUp(() => reloj = RelojPrueba());

  test('el PIN se guarda como huella y nunca en claro', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);

    await pin.crear('1234');

    final hash = prefs.getString(PinStore.claveHash);
    expect(hash, isNotNull);
    expect(hash, isNot('1234'));
    // Huella PBKDF2-SHA256 = 32 bytes en hex = 64 caracteres.
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash!), isTrue);

    // Ninguna clave guardada contiene el PIN en claro.
    for (final clave in prefs.getKeys()) {
      expect(prefs.get(clave), isNot('1234'));
    }

    expect(await pin.verificar('1234'), VerificacionPin.correcto);
    expect(await pin.verificar('9999'), VerificacionPin.incorrecto);
    // Un fallo no bloquea: van 1 de 5.
    expect(pin.intentosFallidos, 1);
  });

  test('cada PIN usa una sal distinta', () async {
    final prefsA = await prefsDePrueba();
    final prefsB = await prefsDePrueba();
    final a = await store(prefsA);
    final b = await store(prefsB);

    await a.crear('1234');
    await b.crear('1234');

    final salA = prefsA.getString(PinStore.claveSalt);
    final salB = prefsB.getString(PinStore.claveSalt);
    expect(salA, isNot(salB));
  });

  test('cinco intentos fallidos activan el bloqueo de 60 segundos', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('1234');

    for (var intento = 1; intento <= 4; intento++) {
      expect(
        await pin.verificar('0000'),
        VerificacionPin.incorrecto,
        reason: 'fallo $intento',
      );
      expect(pin.bloqueoRestante(), Duration.zero);
      expect(pin.intentosFallidos, intento);
    }

    // Quinto fallo: 60 s exactos con el reloj de prueba.
    expect(await pin.verificar('0000'), VerificacionPin.incorrecto);
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);
    expect(PinStore.esperaDeBloqueo, const Duration(seconds: 60));

    // Mientras dura la espera ni el código correcto desbloquea.
    expect(await pin.verificar('1234'), VerificacionPin.bloqueado);
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);

    reloj.avanzar(const Duration(seconds: 60));
    expect(pin.bloqueoRestante(), Duration.zero);
    expect(await pin.verificar('1234'), VerificacionPin.correcto);
  });

  test('los intentos y el bloqueo persisten al crear otra instancia',
      () async {
    final prefs = await prefsDePrueba();
    final primero = await store(prefs);
    await primero.crear('1234');

    await primero.verificar('0000');
    await primero.verificar('1111');
    expect(primero.intentosFallidos, 2);

    // Nueva instancia = app reiniciada: el contador sigue ahí.
    final trasReinicio = await store(prefs);
    expect(trasReinicio.creado, isTrue);
    expect(trasReinicio.intentosFallidos, 2);

    for (var i = 0; i < 3; i++) {
      await trasReinicio.verificar('2222');
    }
    expect(trasReinicio.bloqueoRestante(), PinStore.esperaDeBloqueo);

    final bloqueada = await store(prefs);
    expect(bloqueada.bloqueoRestante(), PinStore.esperaDeBloqueo);
  });

  test('una huella corrupta se trata como código incorrecto', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('1234');
    await prefs.setString(PinStore.claveHash, 'zz');

    expect(await pin.verificar('1234'), VerificacionPin.incorrecto);
  });

  test('crear un PIN exige cuatro dígitos', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);

    await expectLater(pin.crear('123'), throwsFormatException);
    await expectLater(pin.crear('12ab'), throwsFormatException);
    expect(pin.creado, isFalse);
  });
}
