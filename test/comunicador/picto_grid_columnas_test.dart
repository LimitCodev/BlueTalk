import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/comunicador/comunicador_picto_grid.dart';
import 'package:bluetalk/data/models/models.dart';

const _pictos = [
  Pictogram(id: 'a', categoryId: 'c', label: 'A', asset: 'no-existe.svg'),
];

Future<int> _columnas(WidgetTester tester, Size tamano) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamano;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        home: Scaffold(body: PictoGrid(pictograms: _pictos, emptyText: '')),
      ),
    ),
  );
  final delegate = tester.widget<GridView>(find.byType(GridView)).gridDelegate;
  return (delegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount;
}

void main() {
  testWidgets('girar el teléfono no cambia las columnas', (tester) async {
    expect(await _columnas(tester, const Size(360, 640)), 3);
    expect(await _columnas(tester, const Size(640, 360)), 3);
  });

  testWidgets('una tableta usa más columnas, también fijas', (tester) async {
    expect(await _columnas(tester, const Size(800, 1280)), 6);
    expect(await _columnas(tester, const Size(1280, 800)), 6);
  });
}
