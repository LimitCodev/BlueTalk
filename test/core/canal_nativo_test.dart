import 'package:bluetalk/core/plataforma/canal_nativo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = CanalNativo('bluetalk/prueba');
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void responder(Future<Object?>? Function(MethodCall) h) => mensajero
      .setMockMethodCallHandler(const MethodChannel('bluetalk/prueba'), h);

  tearDown(() => responder((_) => null));

  test('sin canal devuelve null y la orden es false', () async {
    expect(await canal.mapa('estado'), isNull);
    expect(await canal.orden('activar'), isFalse);
  });

  test('pasa argumentos y devuelve la respuesta', () async {
    responder((c) async => {'eco': c.arguments});
    expect(await canal.mapa('estado', 7), {'eco': 7});
  });

  test('un fallo de Android se vuelve null, no una excepción', () async {
    responder((_) async => throw PlatformException(code: 'x'));
    expect(await canal.pedir<bool>('activar'), isNull);
    expect(await canal.orden('activar'), isFalse);
  });
}
