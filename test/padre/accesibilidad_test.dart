import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/control/cambiar_codigo.dart';
import 'package:bluetalk/features/padre/control/control_screen.dart';
import 'package:bluetalk/features/padre/dashboard/resumen_screen.dart';
import 'package:bluetalk/features/padre/gate/gate_screen.dart';
import 'package:bluetalk/features/padre/gate/recuperar_screen.dart';
import 'package:bluetalk/features/padre/legal/legal_screen.dart';
import 'package:bluetalk/features/padre/salud_padre/salud_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

/// Auditoría de accesibilidad de la zona del modo padre (plan 08).
///
/// El resumen va el primero: es el único testWidgets del archivo que
/// necesita el canal de assets (los seeds se leen del disco en cuanto el
/// bundle contesta), así como el resto se queda con datos de prefs.
void main() {
  testWidgets('el resumen del padre es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: ResumenScreen()),
    );
  });

  testWidgets('el gate del modo padre es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: GateScreen()),
    );
  });

  testWidgets('el control parental es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: ControlScreen()),
    );
  });

  testWidgets('la salud del padre es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: SaludPadreScreen()),
    );
  });

  testWidgets('los documentos legales son accesibles', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: LegalScreen()),
    );
  });

  testWidgets('el gate con PIN creado es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: GateScreen()),
    );
  });

  testWidgets('la pantalla de recuperación del código es accesible',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(body: RecuperarScreen()),
    );
  });

  testWidgets('el diálogo de cambiar código es accesible', (tester) async {
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs),
      home: const Scaffold(
        body: Center(
          child: SizedBox(width: 360, child: CambiarCodigoDialogo()),
        ),
      ),
    );
  });
}
