import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Prueba de extremo a extremo del filtro DNS local (plan 14).
///
/// Requiere un emulador o teléfono con red. No forma parte de `flutter test`:
/// se ejecuta con
/// `flutter test integration_test/filtro_web_test.dart -d emulator-5554`.
/// La prueba deja la VPN apagada al terminar.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('bluetalk/filtro_web');

  testWidgets('la VPN local bloquea un dominio y deja pasar otro',
      (tester) async {
    await tester.runAsync(() async {
      try {
        const config = '{"activo":true,"dominios":'
            '["example.com","use-application-dns.net"]}';
        await canal.invokeMethod<void>('actualizar', {'config': config});
        final activado = await canal.invokeMethod<bool>('activar');
        expect(activado, isTrue);

        Map<Object?, Object?>? estado;
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 250));
          estado = await canal.invokeMethod<Map<Object?, Object?>>('estado');
          if (estado?['activo'] == true) break;
        }
        expect(estado?['activo'], isTrue, reason: 'La VPN no arrancó: $estado');

        final bloqueado = await _resuelve('example.com');
        expect(bloqueado, isFalse, reason: 'example.com debía bloquearse');

        final permitido = await _resuelve('wikipedia.org');
        expect(permitido, isTrue, reason: 'Un dominio permitido no resuelve');

        final estadoFinal =
            await canal.invokeMethod<Map<Object?, Object?>>('estado');
        final bloqueos = estadoFinal?['bloqueos'];
        expect(bloqueos, isA<List<Object?>>());
        final dominios = (bloqueos! as List<Object?>)
            .whereType<Map<Object?, Object?>>()
            .map((item) => item['dominio'])
            .toList();
        expect(dominios, contains('example.com'));
      } finally {
        await canal.invokeMethod<void>('desactivar');
      }
    });
  });
}

Future<bool> _resuelve(String host) async {
  try {
    final ips = await InternetAddress.lookup(host);
    return ips.isNotEmpty;
  } on SocketException {
    return false;
  }
}
