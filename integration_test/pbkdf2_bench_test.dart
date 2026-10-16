import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bluetalk/features/padre/gate/pin_store.dart';

/// Mide la derivación PBKDF2 real en el dispositivo o emulador (plan 11
/// §1.2.2): se elige la mayor cantidad de iteraciones que siga por debajo
/// de 500 ms por intento de login.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bench de PBKDF2 en el dispositivo', (tester) async {
    const derivador = DerivadorPinAislamiento();
    final sal = List<int>.generate(16, (i) => i + 1);

    for (final iteraciones in [10000, 25000, 50000, 100000, 200000, 400000]) {
      final cronometro = Stopwatch()..start();
      final hash = await derivador.derivar('123456', sal, iteraciones);
      cronometro.stop();
      // ignore: avoid_print
      print(
        'PBKDF2 $iteraciones iteraciones: '
        '${cronometro.elapsedMilliseconds} ms (hash ${hash.length} bytes)',
      );
    }
  });
}
