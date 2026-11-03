import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/theme/app_colors.dart';
import 'package:bluetalk/core/theme/app_theme.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/picto_tile.dart';

/// Las tarjetas de pictograma se tiñen con el tono de su categoría, igual
/// que la web (`docs/branding/WEB-EXTRACCION.md` §2: relleno `--cat-*` en
/// alpha bajo y borde al 30 %). En claro se usan los pasteles de la app
/// (AA); en oscuro se aplica la regla de alpha de la web sobre el mismo
/// tono, porque el pastel sería un bloque claro sobre la página oscura.
void main() {
  const picto = Pictogram(
    id: 'e1',
    categoryId: 'emociones',
    label: 'Feliz',
    asset: 'assets/pictos/muestra/feliz.svg',
  );

  Future<Material> pintar(WidgetTester tester, AppColors paleta,
      {ColoresCategoria? categoria}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBlueTalkTheme(paleta),
        home: Scaffold(
          body: PictoTile(
            pictogram: picto,
            categoria: categoria,
            onTap: () {},
          ),
        ),
      ),
    );
    return tester.widget<Material>(
      find.descendant(
        of: find.byType(PictoTile),
        matching: find.byType(Material),
      ),
    );
  }

  testWidgets('en claro usa el pastel de la categoría y su borde',
      (tester) async {
    final categoria = coloresCategorias['emociones']!;
    final material = await pintar(tester, AppColors.celeste,
        categoria: categoria);
    expect(material.color, categoria.fondo);
    final borde = (material.shape! as RoundedRectangleBorder).side.color;
    expect(borde, categoria.borde);
  });

  testWidgets('en oscuro aplica la regla de alpha de la web sobre el tono',
      (tester) async {
    final categoria = coloresCategorias['emociones']!;
    final material =
        await pintar(tester, AppColors.oscuro, categoria: categoria);
    expect(material.color, categoria.tinta.withValues(alpha: 0.10));
    final borde = (material.shape! as RoundedRectangleBorder).side.color;
    expect(borde, categoria.tinta.withValues(alpha: 0.30));
    // Nunca el pastel claro: sería un bloque brillante sobre la página.
    expect(material.color, isNot(categoria.fondo));
  });

  testWidgets('sin categoría queda neutra, como en Inicio o búsqueda',
      (tester) async {
    final material = await pintar(tester, AppColors.celeste);
    expect(material.color, AppColors.celeste.surface);
    final borde = (material.shape! as RoundedRectangleBorder).side.color;
    expect(borde, AppColors.bordeNeutro);
  });
}
