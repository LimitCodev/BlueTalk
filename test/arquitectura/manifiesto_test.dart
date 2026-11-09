import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P0-3 de Play: la edición publicable no puede declarar administrador de
/// dispositivo para bloquear la desinstalación. Estos tests lo impiden por
/// descuido, aunque alguien vuelva a añadir el receptor en cualquier
/// source set.
void main() {
  final raizAndroid = Directory('android/app/src');

  test('ningún manifiesto fuente declara administrador de dispositivo', () {
    final manifiestos = raizAndroid
        .listSync(recursive: true)
        .whereType<File>()
        .where((archivo) => archivo.path.endsWith('AndroidManifest.xml'))
        .toList();

    // Control positivo: el recorrido encontró los manifiestos de main,
    // debug y profile. Si la ruta cambiara, el test no pasaría en vacío.
    expect(manifiestos, isNotEmpty);

    for (final manifiesto in manifiestos) {
      final texto = manifiesto.readAsStringSync();

      expect(
        texto,
        isNot(contains('BIND_DEVICE_ADMIN')),
        reason: '${manifiesto.path} declara BIND_DEVICE_ADMIN',
      );
      expect(
        texto,
        isNot(contains('ProteccionReceiver')),
        reason: '${manifiesto.path} declara ProteccionReceiver',
      );
      expect(
        texto,
        isNot(contains('device_admin')),
        reason: '${manifiesto.path} referencia device_admin',
      );
    }
  });

  test('el manifiesto principal sigue siendo el de la app', () {
    final texto = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    // Control positivo: si el archivo se vaciara, las aserciones de arriba
    // pasarían sin comprobar nada.
    expect(texto, contains('<application'));
    expect(texto, contains('FiltroWebVpnService'));
  });

  test('no quedan el canal nativo ni el XML del administrador', () {
    final mainActivity = File(
      'android/app/src/main/kotlin/com/limitcodev/bluetalk/MainActivity.kt',
    ).readAsStringSync();

    expect(mainActivity, isNot(contains('ProteccionChannel')));
    expect(
      File(
        'android/app/src/main/kotlin/com/limitcodev/bluetalk/'
        'ProteccionChannel.kt',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('android/app/src/main/res/xml/device_admin.xml').existsSync(),
      isFalse,
    );
  });
}
