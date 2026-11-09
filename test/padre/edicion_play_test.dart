import 'package:bluetalk/core/plataforma/edicion.dart';
import 'package:bluetalk/features/padre/control/control_screen.dart';
import 'package:bluetalk/features/padre/legal/textos_legales.dart';
import 'package:bluetalk/features/padre/perfil_edad.dart';
import 'package:bluetalk/features/padre/permisos/permiso_model.dart';
import 'package:bluetalk/features/padre/permisos/permisos_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Ruta A: la edición Play no enseña nada del filtro ni del acceso al uso.
void main() {
  test('sin sabor se comporta como Play', () {
    expect(edicionDirecta, isFalse);
  });

  test('Play solo pide el permiso de avisos', () async {
    final prefs = await prefsDePrueba();
    final container = ProviderContainer(
      overrides: overridesDePadre(prefs, edicionDirecta: false).cast(),
    );
    addTearDown(container.dispose);

    final estado = await container.read(permisosProvider.future);
    expect(estado.permisos.map((p) => p.id), [PermisoId.avisos]);
  });

  testWidgets('Control no enseña el filtro ni el tiempo por app en Play', (
    tester,
  ) async {
    final prefs = await prefsDePrueba();
    await pumpPadre(
      tester,
      home: const Scaffold(body: ControlScreen()),
      overrides: overridesDePadre(prefs, edicionDirecta: false),
    );

    expect(find.text('Filtro de páginas'), findsNothing);
    expect(find.text('Tiempo por app'), findsNothing);
  });

  test('los textos legales de Play no mencionan el filtro', () {
    for (final texto in [politicaDePrivacidad, terminosYCondiciones]) {
      expect(texto.length, greaterThan(1000));
      expect(texto.toLowerCase(), isNot(contains('vpn')));
      expect(texto.toLowerCase(), isNot(contains('filtro')));
      expect(texto, isNot(contains('DNS')));
    }
  });

  test('las explicaciones del perfil pierden solo las frases del filtro', () {
    expect(quitarFrasesDeFiltro(PerfilEdad.ninguno.explicacion), 'Se ve todo.');
    for (final perfil in PerfilEdad.values) {
      final texto = quitarFrasesDeFiltro(perfil.explicacion);
      expect(texto, isNotEmpty);
      expect(texto, isNot(contains('filtro')));
    }
  });
}
