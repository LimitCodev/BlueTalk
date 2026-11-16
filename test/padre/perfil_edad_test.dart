import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/almacen/almacen_local.dart';
import 'package:bluetalk/features/comunicador/comunicador_catalog.dart';
import 'package:bluetalk/features/padre/control/control_screen.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_controller.dart';
import 'package:bluetalk/features/padre/perfil_edad.dart';

import 'harness.dart';

void main() {
  group('PerfilEdad', () {
    test('una edad desconocida vuelve a «sin perfil»', () {
      expect(PerfilEdad.desdeNombre('nada'), PerfilEdad.ninguno);
      expect(PerfilEdad.desdeNombre(null), PerfilEdad.ninguno);
      expect(PerfilEdad.desdeNombre('pequenas'), PerfilEdad.pequenas);
    });

    test('solo se ven las categorías de la edad elegida', () {
      expect(PerfilEdad.ninguno.seVe('clima'), isTrue);
      expect(PerfilEdad.pequenas.seVe('emociones'), isTrue);
      expect(PerfilEdad.pequenas.seVe('clima'), isFalse);
      expect(PerfilEdad.pequenas.seVe('acciones'), isFalse);
      expect(PerfilEdad.medianas.seVe('acciones'), isTrue);
      expect(PerfilEdad.medianas.seVe('clima'), isTrue);
      expect(PerfilEdad.mayores.seVe('clima'), isTrue);
    });
  });

  group('elegir el perfil', () {
    test('se guarda y ajusta el filtro de páginas a esa edad', () async {
      final prefs = await prefsDePrueba();
      final container = ProviderContainer(
        overrides: overridesDePadre(prefs).cast(),
      );
      addTearDown(container.dispose);

      expect(container.read(perfilEdadProvider), PerfilEdad.ninguno);

      await container.read(perfilEdadProvider.notifier).elegir(
            PerfilEdad.pequenas,
          );

      expect(container.read(perfilEdadProvider), PerfilEdad.pequenas);
      expect(prefs.getString(PerfilEdad.clavePref), 'pequenas');

      // El filtro se ajusta: para 3 a 5 años también vídeos, juegos y
      // buscadores, y el SafeSearch queda encendido.
      final filtro = container.read(filtroWebProvider);
      expect(filtro.bloquearJuegos, isTrue);
      expect(filtro.bloquearBuscadores, isTrue);
      expect(filtro.forzarSafeSearch, isTrue);

      // Tras un reinicio se recuerda.
      expect(PerfilEdad.desdePrefs(AlmacenPrefs(prefs)), PerfilEdad.pequenas);
    });

    test('el catálogo oculta las categorías que no tocan y conserva los pictos',
        () async {
      final prefs = await prefsDePrueba();
      final container = ProviderContainer(
        overrides: overridesDePadre(prefs).cast(),
      );
      addTearDown(container.dispose);

      final completo = await container.read(catalogProvider.future);
      expect(completo.categories.length, greaterThan(4));

      await container.read(perfilEdadProvider.notifier).elegir(
            PerfilEdad.pequenas,
          );
      final reducido = await container.read(catalogProvider.future);

      expect(reducido.categories.map((c) => c.id), [
        'basicas',
        'emociones',
        'comida',
        'animales',
        'familia',
      ]);
      expect(
        reducido.pictograms.length,
        completo.pictograms.length,
        reason: 'los pictogramas no se borran: una frase guardada sigue '
            'pudiendo resolverlos',
      );
      expect(reducido.pictogramById('sun'), isNotNull);
    });
  });

  group('pantalla de control', () {
    testWidgets('elegir una edad desde el diálogo se refleja en la pantalla',
        (tester) async {
      final prefs = await prefsDePrueba();
      final container = await pumpPadre(
        tester,
        home: const Scaffold(body: ControlScreen()),
        overrides: overridesDePadre(prefs),
      );

      expect(find.text('Perfil de edad'), findsOneWidget);
      expect(find.textContaining('Sin perfil'), findsOneWidget);

      // El nombre del niño (plan 14A) va encima y baja esta fila.
      await tester.ensureVisible(find.text('Perfil de edad'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perfil de edad'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil de edad'), findsWidgets);
      await tester.tap(find.text('3 a 5 años'));
      await tester.pumpAndSettle();

      expect(container.read(perfilEdadProvider), PerfilEdad.pequenas);
      expect(
        find.textContaining('3 a 5 años'),
        findsOneWidget,
        reason: 'la pantalla de control enseña el perfil elegido',
      );
    });
  });
}
