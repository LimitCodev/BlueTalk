import 'dart:convert';
import 'dart:io';

import 'package:bluetalk/core/theme/colores_gramatica.dart';
import 'package:bluetalk/data/contracts/repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/comunicador_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Mayor que los 20 KB del plan 11: abuelos, comer, jugar y familia no bajan
// sin perder detalle (nota en docs/informes/etapa-c-evidencia.md).
const _maxBytes = 32 * 1024;
const _maxTotal = 3 * 1024 * 1024;

List<Map<String, dynamic>> _seed(String nombre) =>
    (jsonDecode(File('assets/seed/$nombre.json').readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

class _RepoDesordenado implements PictogramRepo {
  @override
  Future<List<Category>> categories() async => const [
    Category(id: 'n', name: 'N', icon: 'a', tipo: 'nuclear'),
  ];

  @override
  Future<List<Pictogram>> pictogramsOf(String categoryId) async => [
    for (final o in [3, 1, 2])
      Pictogram(id: '$o', categoryId: 'n', label: '$o', asset: '', order: o),
  ];

  @override
  Future<Pictogram?> pictogram(String id) async => null;
}

void main() {
  final pictos = _seed('pictogramas').map(Pictogram.fromMap).toList();
  final categorias = _seed('categorias').map(Category.fromMap).toList();
  final nucleares = pictos.where((p) => p.categoryId == 'basicas').toList();

  test('ids únicos, categoría existente y etiqueta no vacía', () {
    final ids = pictos.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    final catIds = categorias.map((c) => c.id).toSet();
    for (final p in pictos) {
      expect(catIds, contains(p.categoryId), reason: p.id);
      expect(p.label.trim(), isNotEmpty, reason: p.id);
    }
  });

  test('cada SVG existe y cabe en el presupuesto', () {
    var total = 0;
    for (final asset in pictos.map((p) => p.asset).toSet()) {
      final archivo = File(asset);
      expect(archivo.existsSync(), isTrue, reason: asset);
      expect(archivo.lengthSync(), lessThanOrEqualTo(_maxBytes), reason: asset);
      total += archivo.lengthSync();
    }
    expect(total, lessThanOrEqualTo(_maxTotal));
  });

  testWidgets('flutter_svg puede leer cada SVG (nunca un hueco)', (tester) async {
    for (final asset in pictos.map((p) => p.asset).toSet()) {
      final svg = File(asset).readAsStringSync();
      await tester.runAsync(
        () => vg.loadPicture(SvgStringLoader(svg), null),
      );
    }
  });

  test('el icono de cada categoría es un pictograma real', () {
    final ids = pictos.map((p) => p.id).toSet();
    for (final c in categorias) {
      expect(ids, contains(c.icon), reason: c.id);
    }
  });

  test('tablero nuclear: orden 1..n sin huecos y clase con color', () {
    expect(nucleares.map((p) => p.order).toSet(), {
      for (var i = 1; i <= nucleares.length; i++) i,
    });
    for (final p in nucleares) {
      expect(coloresDeClase(p.clase), isNotNull, reason: p.id);
    }
  });

  test('las posiciones nucleares no cambian (memoria motora)', () {
    int? posicion(String label) =>
        nucleares.firstWhere((p) => p.label == label).order;
    expect(posicion('Yo'), 1);
    expect(posicion('Quiero'), 6);
    expect(posicion('Más'), 29);
    expect(posicion('Sí'), 47);
    expect(posicion('No'), 48);
    expect(posicion('Qué'), 66);
  });

  test('el catálogo ordena el tablero nuclear solo por order', () async {
    final catalogo = await Catalog.load(_RepoDesordenado());
    expect(catalogo.pictogramsOf('n').map((p) => p.order), [1, 2, 3]);
  });
}
