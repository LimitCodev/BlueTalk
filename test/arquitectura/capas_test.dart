import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reglas de capas que el compilador no vigila (función de aptitud).
///
/// Si una falla, no la relajes: mueve el acceso a su puerta del core.
void main() {
  List<File> dartDe(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  List<String> quienesUsan(String patron, {required List<String> permitidos}) =>
      dartDe('lib')
          .where((f) => !permitidos.any((p) => f.path.startsWith(p)))
          .where((f) => f.readAsStringSync().contains(patron))
          .map((f) => f.path)
          .toList();

  test('solo core/almacen y data/local importan shared_preferences', () {
    final fuera = quienesUsan(
      'package:shared_preferences/',
      permitidos: [
        'lib/core/almacen/',
        'lib/data/local/',
        'lib/app/di.dart', // raíz de composición
        'lib/main.dart',
      ],
    );
    expect(fuera, isEmpty, reason: 'Usa almacenLocalProvider (core/almacen).');
  });

  test('solo core/plataforma crea canales nativos', () {
    final fuera = quienesUsan(
      'MethodChannel(',
      permitidos: ['lib/core/plataforma/'],
    );
    expect(fuera, isEmpty, reason: 'Usa CanalNativo (core/plataforma).');
  });
}
