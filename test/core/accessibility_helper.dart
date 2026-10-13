import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:accessibility_tools/src/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Purga [app] envuelta en `accessibility_tools`, recoge los problemas que el
/// checker solo loguea (no lanza) y desmonta para liberar los
/// `SemanticsHandle` — el nuestro y el que el paquete crea en `initState`.
///
/// Nota: los handles se liberan aquí mismo, dentro del cuerpo del test:
/// `_endOfTestVerifications` corre antes que los `addTearDown`, así que
/// dejarlos para el teardown haría fallar el test.
Future<List<String>> problemasDeAccesibilidad(
  WidgetTester tester,
  Widget app,
) async {
  AccessibilityTools.debugRunCheckersInTests = true;

  final issues = <String>[];
  final originalDebugPrint = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    final text = message ?? '';
    if (text.contains('ACCESSIBILITY ISSUES FOUND')) issues.add(text);
    // El detalle de cada issue llega en mensajes posteriores.
    if (text.startsWith('Accessibility issue')) issues.add(text);
  };

  final semantics = tester.ensureSemantics();
  try {
    await tester.pumpWidget(app);
    // Los checkers corren sobre el árbol de semántica tras cada frame:
    // settle deja terminar la carga asíncrona (p.ej. perfil inicial).
    await tester.pumpAndSettle();
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
    debugPrint = originalDebugPrint;
    AccessibilityTools.debugRunCheckersInTests = false;
  }
  return issues;
}

/// Auditoría de targets táctiles ≥48dp y semántica para una pantalla suelta
/// (patrón del propio paquete: checker dentro del `MaterialApp.builder`).
///
/// El checker trabaja sobre la capa de semántica (área táctil real), así que
/// no da falsos positivos con widgets internos decorativos, a diferencia de
/// medir tamaños de widget a mano.
Future<void> expectSinProblemasDeAccesibilidad(
  WidgetTester tester, {
  required List<Object> overrides,
  required Widget home,
}) async {
  final issues = await problemasDeAccesibilidad(
    tester,
    ProviderScope(
      // Riverpod 3 no exporta el tipo `Override` (solo se infiere):
      // cast() lo deduce del parámetro de ProviderScope.
      overrides: overrides.cast(),
      child: MaterialApp(
        builder: (context, child) => AccessibilityTools(child: child!),
        home: home,
      ),
    ),
  );

  expect(
    issues,
    isEmpty,
    reason: 'Problemas de accesibilidad (targets <48dp u otros):\n'
        '${issues.join('\n')}',
  );
}
