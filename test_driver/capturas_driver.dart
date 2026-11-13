import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Guarda las capturas de los gráficos del adulto (plan 14C §5 paso 8).
Future<void> main() => integrationDriver(
      onScreenshot: (nombre, bytes, [args]) async {
        final carpeta = Directory('docs/informes/capturas')
          ..createSync(recursive: true);
        File('${carpeta.path}/$nombre.png').writeAsBytesSync(bytes);
        return true;
      },
    );
