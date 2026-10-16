import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

/// Recibe el informe de `traceAction` y guarda el resumen del timeline
/// (plan 11 §1.3.2: cifras reales en el commit PERF).
Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        for (final clave in data.keys) {
          final informe = data[clave];
          if (informe is Map<String, dynamic>) {
            final fichero = File('build/$clave.timeline_summary.json');
            await fichero.writeAsString(jsonEncode(informe));
            // ignore: avoid_print
            print('timeline guardado en ${fichero.path}');
          }
        }
      },
    );
