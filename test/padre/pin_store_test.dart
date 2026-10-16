import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/padre/gate/pin_store.dart';

import 'harness.dart';

String _hex(List<int> bytes) => [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RelojPrueba reloj;

  Future<PinStore> store(SharedPreferences prefs) async =>
      PinStore(prefs, ahora: reloj.decir, derivador: const DerivadorPinPrueba());

  setUp(() => reloj = RelojPrueba());

  test('el PIN se guarda como huella y nunca en claro', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);

    await pin.crear('123456');

    final hash = prefs.getString(PinStore.claveHash);
    expect(hash, isNotNull);
    expect(hash, isNot('123456'));
    // Huella PBKDF2-SHA256 = 32 bytes en hex = 64 caracteres.
    expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash!), isTrue);

    // Ninguna clave guardada contiene el PIN en claro.
    for (final clave in prefs.getKeys()) {
      expect(prefs.get(clave), isNot('123456'));
    }

    // Los parámetros de la huella quedan registrados junto a ella.
    expect(prefs.getInt(PinStore.claveLongitud), 6);
    expect(prefs.getInt(PinStore.claveIteraciones), PinStore.iteracionesActuales);

    expect(await pin.verificar('123456'), VerificacionPin.correcto);
    expect(await pin.verificar('999999'), VerificacionPin.incorrecto);
    // Un fallo no bloquea: van 1 de 5.
    expect(pin.intentosFallidos, 1);
  });

  test('cada PIN usa una sal distinta', () async {
    final prefsA = await prefsDePrueba();
    final prefsB = await prefsDePrueba();
    final a = await store(prefsA);
    final b = await store(prefsB);

    await a.crear('123456');
    await b.crear('123456');

    final salA = prefsA.getString(PinStore.claveSalt);
    final salB = prefsB.getString(PinStore.claveSalt);
    expect(salA, isNot(salB));
  });

  test('cinco intentos fallidos activan el bloqueo de 60 segundos', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('123456');

    for (var intento = 1; intento <= 4; intento++) {
      expect(
        await pin.verificar('000000'),
        VerificacionPin.incorrecto,
        reason: 'fallo $intento',
      );
      expect(pin.bloqueoRestante(), Duration.zero);
      expect(pin.intentosFallidos, intento);
    }

    // Quinto fallo: 60 s exactos con el reloj de prueba.
    expect(await pin.verificar('000000'), VerificacionPin.incorrecto);
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);
    expect(PinStore.esperaDeBloqueo, const Duration(seconds: 60));
    expect(pin.nivelBloqueo, 1);

    // Mientras dura la espera ni el código correcto desbloquea.
    expect(await pin.verificar('123456'), VerificacionPin.bloqueado);
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);

    reloj.avanzar(const Duration(seconds: 60));
    expect(pin.bloqueoRestante(), Duration.zero);
    expect(await pin.verificar('123456'), VerificacionPin.correcto);

    // Acertar limpia el nivel y el bloqueo.
    expect(pin.nivelBloqueo, 0);
    expect(prefs.containsKey(PinStore.claveBloqueo), isFalse);
    expect(prefs.containsKey(PinStore.claveBloqueoDesde), isFalse);
    expect(prefs.containsKey(PinStore.claveNivel), isFalse);
  });

  test('los intentos y el bloqueo persisten al crear otra instancia',
      () async {
    final prefs = await prefsDePrueba();
    final primero = await store(prefs);
    await primero.crear('123456');

    await primero.verificar('000000');
    await primero.verificar('111111');
    expect(primero.intentosFallidos, 2);

    // Nueva instancia = app reiniciada: el contador sigue ahí.
    final trasReinicio = await store(prefs);
    expect(trasReinicio.creado, isTrue);
    expect(trasReinicio.intentosFallidos, 2);

    for (var i = 0; i < 3; i++) {
      await trasReinicio.verificar('222222');
    }
    expect(trasReinicio.bloqueoRestante(), PinStore.esperaDeBloqueo);
    expect(trasReinicio.nivelBloqueo, 1);

    final bloqueada = await store(prefs);
    expect(bloqueada.bloqueoRestante(), PinStore.esperaDeBloqueo);
  });

  test('una huella corrupta se trata como código incorrecto', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('123456');
    await prefs.setString(PinStore.claveHash, 'zz');

    expect(await pin.verificar('123456'), VerificacionPin.incorrecto);
  });

  test('crear un PIN exige seis dígitos', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);

    await expectLater(pin.crear('12345'), throwsFormatException);
    await expectLater(pin.crear('1234567'), throwsFormatException);
    await expectLater(pin.crear('1234'), throwsFormatException);
    await expectLater(pin.crear('12ab'), throwsFormatException);
    expect(pin.creado, isFalse);
  });

  test('un PIN antiguo de 4 dígitos sigue funcionando y se migra al acceder',
      () async {
    final prefs = await prefsDePrueba();
    // Esquema anterior a la versión de 6 dígitos: huella + sal y nada más
    // (sin `padre_pin_len` ni `padre_pin_iter`, que no se guardaban).
    await crearPinDePrueba(prefs);
    await prefs.remove(PinStore.claveLongitud);
    await prefs.remove(PinStore.claveIteraciones);
    final huellaOriginal = prefs.getString(PinStore.claveHash);
    final salOriginal = prefs.getString(PinStore.claveSalt);

    final pin = await store(prefs);
    expect(pin.creado, isTrue);
    expect(pin.longitudGuardada, 4);
    expect(pin.iteracionesGuardadas, PinStore.iteracionesAntiguas);

    // El PIN de 4 dígitos entra; uno de 6 no vale para este PIN.
    expect(await pin.verificar('1234'), VerificacionPin.correcto);
    expect(await pin.verificar('123456'), VerificacionPin.incorrecto);

    // Tras el acceso, los parámetros quedan registrados y la huella se
    // re-hashea con sal nueva; el PIN de 4 dígitos sigue abriendo.
    expect(prefs.getInt(PinStore.claveLongitud), 4);
    expect(prefs.getInt(PinStore.claveIteraciones), PinStore.iteracionesActuales);
    expect(prefs.getString(PinStore.claveHash), isNot(huellaOriginal));
    expect(prefs.getString(PinStore.claveSalt), isNot(salOriginal));
    expect(await pin.verificar('1234'), VerificacionPin.correcto);
    expect(await pin.verificar('9999'), VerificacionPin.incorrecto);
  });

  test('un PIN hasheado con iteraciones viejas se re-hashea tras el acceso',
      () async {
    final prefs = await prefsDePrueba();
    // Huella calculada con 5.000 iteraciones, como haría una versión
    // anterior con parámetros distintos.
    const salt = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    final huellaVieja = await const DerivadorPinPrueba().derivar(
      '123456',
      salt,
      5000,
    );
    await prefs.setString(PinStore.claveSalt, _hex(salt));
    await prefs.setString(PinStore.claveHash, _hex(huellaVieja));
    await prefs.setInt(PinStore.claveIteraciones, 5000);
    await prefs.setInt(PinStore.claveLongitud, 6);

    final pin = await store(prefs);
    expect(await pin.verificar('123456'), VerificacionPin.correcto);

    // La huella ahora está con los parámetros actuales y sigue abriendo.
    expect(prefs.getInt(PinStore.claveIteraciones), PinStore.iteracionesActuales);
    expect(prefs.getString(PinStore.claveHash), isNot(_hex(huellaVieja)));
    expect(await pin.verificar('123456'), VerificacionPin.correcto);
  });

  test('el bloqueo escala 60, 120, 300 y 900 segundos con tope en 900',
      () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('123456');

    Future<void> fallarCinco(String motivo) async {
      for (var intento = 1; intento <= PinStore.intentosMaximos; intento++) {
        expect(
          await pin.verificar('000000'),
          VerificacionPin.incorrecto,
          reason: '$motivo: fallo $intento',
        );
      }
    }

    await fallarCinco('primer ciclo');
    expect(pin.bloqueoRestante(), const Duration(seconds: 60));
    expect(pin.nivelBloqueo, 1);

    reloj.avanzar(const Duration(seconds: 60));
    await fallarCinco('segundo ciclo');
    expect(pin.bloqueoRestante(), const Duration(seconds: 120));
    expect(pin.nivelBloqueo, 2);

    reloj.avanzar(const Duration(seconds: 120));
    await fallarCinco('tercer ciclo');
    expect(pin.bloqueoRestante(), const Duration(seconds: 300));
    expect(pin.nivelBloqueo, 3);

    reloj.avanzar(const Duration(seconds: 300));
    await fallarCinco('cuarto ciclo');
    expect(pin.bloqueoRestante(), const Duration(seconds: 900));
    expect(pin.nivelBloqueo, 4);

    reloj.avanzar(const Duration(seconds: 900));
    await fallarCinco('quinto ciclo');
    expect(pin.bloqueoRestante(), const Duration(seconds: 900),
        reason: 'el tope es 900 segundos');
    expect(pin.nivelBloqueo, 5);

    // El nivel persiste en otra instancia (app reiniciada).
    final trasReinicio = await store(prefs);
    expect(trasReinicio.nivelBloqueo, 5);
    expect(trasReinicio.bloqueoRestante(), const Duration(seconds: 900));

    // Acertar cuando por fin pasa la espera resetea el nivel.
    reloj.avanzar(const Duration(seconds: 900));
    expect(await pin.verificar('123456'), VerificacionPin.correcto);
    expect(pin.nivelBloqueo, 0);
    expect(prefs.containsKey(PinStore.claveNivel), isFalse);
  });

  test('un reloj atrasado no acorta el bloqueo', () async {
    final prefs = await prefsDePrueba();
    final pin = await store(prefs);
    await pin.crear('123456');

    for (var i = 0; i < PinStore.intentosMaximos; i++) {
      await pin.verificar('000000');
    }
    expect(pin.bloqueoRestante(), const Duration(seconds: 60));

    // Atrasan el reloj 2 horas: el bloqueo no se acorta ni desaparece.
    reloj.avanzar(const Duration(hours: -2));
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);
    expect(await pin.verificar('123456'), VerificacionPin.bloqueado);

    // Con el reloj atrasado el tiempo no avanza dentro del bloqueo.
    reloj.avanzar(const Duration(minutes: 1));
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);
    expect(await pin.verificar('123456'), VerificacionPin.bloqueado);

    // Reloj restaurado al inicio del bloqueo: vuelven a contar los 60 s.
    reloj.ahora = ahoraFija;
    expect(pin.bloqueoRestante(), PinStore.esperaDeBloqueo);
    reloj.avanzar(const Duration(seconds: 60));
    expect(pin.bloqueoRestante(), Duration.zero);
    expect(await pin.verificar('123456'), VerificacionPin.correcto);
  });

  test('formatos inválidos no cuentan intentos ni rompen el gate', () async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs); // PIN antiguo de 4 dígitos.
    final pin = await store(prefs);

    expect(await pin.verificar('123'), VerificacionPin.incorrecto);
    expect(await pin.verificar('123456'), VerificacionPin.incorrecto,
        reason: 'un PIN de 4 dígitos no admite 6');
    expect(await pin.verificar('12ab'), VerificacionPin.incorrecto);
    expect(await pin.verificar(''), VerificacionPin.incorrecto);
    expect(pin.intentosFallidos, 0,
        reason: 'un formato inválido no consume intentos');

    // Con un PIN de 6 dígitos pasa lo mismo con los de 4.
    final prefs6 = await prefsDePrueba();
    final pin6 = await store(prefs6);
    await pin6.crear('123456');
    expect(await pin6.verificar('1234'), VerificacionPin.incorrecto);
    expect(pin6.intentosFallidos, 0);
  });

  test('valores corruptos en preferencias no abren ni lanzan excepciones',
      () async {
    Future<PinStore> corrupto(Map<String, Object> iniciales) async {
      final prefs = await prefsDePrueba(iniciales: iniciales);
      return store(prefs);
    }

    final salt = _hex([for (var i = 0; i < 16; i++) i]);
    final huella = _hex([for (var i = 0; i < 32; i++) i]);
    Map<String, Object> base({int longitud = 6, int? iteraciones}) => {
          PinStore.claveSalt: salt,
          PinStore.claveHash: huella,
          PinStore.claveLongitud: longitud,
          PinStore.claveIteraciones: ?iteraciones,
        };

    // Huella que no es hex.
    final pinHashRaro = await corrupto({...base(), PinStore.claveHash: 'zz'});
    expect(await pinHashRaro.verificar('123456'), VerificacionPin.incorrecto);

    // Sal vacía.
    final pinSalVacia = await corrupto({...base(), PinStore.claveSalt: ''});
    expect(await pinSalVacia.verificar('123456'), VerificacionPin.incorrecto);

    // Longitud persistida fuera de rango.
    final pinLenRaro = await corrupto(base(longitud: -3));
    expect(await pinLenRaro.verificar('123456'), VerificacionPin.incorrecto);
    expect(await pinLenRaro.verificar('1234'), VerificacionPin.incorrecto);

    // Iteraciones persistidas fuera de rango (0, negativas o gigantes).
    for (final iteraciones in [0, -5, 1000000000]) {
      final pinIterRara =
          await corrupto(base(longitud: 6, iteraciones: iteraciones));
      expect(
        await pinIterRara.verificar('123456'),
        VerificacionPin.incorrecto,
        reason: 'iteraciones corruptas: $iteraciones',
      );
    }

    // Un valor corrupto de longitud se muestra como 6 para no romper la
    // interfaz, pero no deja pasar a nadie.
    final pinLen = await corrupto(base(longitud: -3));
    expect(pinLen.longitudGuardada, 6);
    expect(await pinLen.verificar('123456'), VerificacionPin.incorrecto);
  });
}
