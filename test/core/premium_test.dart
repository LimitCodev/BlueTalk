import 'package:bluetalk/core/premium/derechos.dart';
import 'package:bluetalk/core/premium/plan.dart';
import 'package:bluetalk/core/premium/premium_providers.dart';
import 'package:bluetalk/core/premium/tienda.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer contenedor(Plan plan) => ProviderContainer(
        overrides: [
          fuenteDerechosProvider.overrideWithValue(DerechosFijos(plan)),
        ],
      );

  test('por defecto (sin dart-define) el plan es gratis', () async {
    expect(await const DerechosFijos().plan(), Plan.gratis);
  });

  test('gratis no abre extras premium', () async {
    final c = contenedor(Plan.gratis);
    addTearDown(c.dispose);
    await c.read(planProvider.future);
    expect(c.read(puedeUsarProvider(Funcion.vocesNaturales)), isFalse);
  });

  test('premium abre todos los extras', () async {
    final c = contenedor(Plan.premium);
    addTearDown(c.dispose);
    await c.read(planProvider.future);
    for (final f in Funcion.values) {
      expect(c.read(puedeUsarProvider(f)), isTrue, reason: f.name);
    }
  });

  test('mientras el plan carga, se trata como gratis', () {
    final c = contenedor(Plan.premium);
    addTearDown(c.dispose);
    expect(c.read(puedeUsarProvider(Funcion.vocesNaturales)), isFalse);
  });

  test('sin Play conectado no se puede comprar', () async {
    const tienda = TiendaNoDisponible();
    expect(await tienda.disponible(), isFalse);
    expect(await tienda.comprar('x'), ResultadoCompra.noDisponible);
  });
}
