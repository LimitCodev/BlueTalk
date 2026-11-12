import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bluetalk/core/plataforma/edicion.dart';
import 'package:bluetalk/core/theme/app_colors.dart';
import 'package:bluetalk/core/theme/app_theme.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/features/padre/informes/informe_modelo.dart';
import 'package:bluetalk/features/padre/informes/informes_providers.dart';
import 'package:bluetalk/features/padre/informes/informes_screen.dart';

DateTime _dia(int menos) =>
    DateTime(2026, 10, 13).subtract(Duration(days: menos));

List<PuntoDia> _serie(int dias, int Function(int) pictos) => [
      for (var i = dias - 1; i >= 0; i--)
        (
          dia: _dia(i),
          pictos: pictos(i),
          segundosJuego: 60 * (i % 4),
          segundosPantalla: null,
        ),
    ];

Informe _lleno(Periodo periodo) => Informe(
      periodo: periodo,
      desde: _dia(periodo.dias - 1),
      hasta: _dia(0),
      diasConDatos: periodo == Periodo.semana ? 6 : 22,
      serie: _serie(periodo.dias, (i) => 6 + (i * 5) % 18),
      actual: const Totales(
        pictos: 120,
        pictosDistintos: 14,
        segundosJuego: 3600,
        sesionesJuego: 8,
        cuentos: 3,
        dibujos: 4,
        actividades: 12,
      ),
      anterior: const Totales(
        pictos: 96,
        pictosDistintos: 12,
        segundosJuego: 3000,
        sesionesJuego: 7,
        cuentos: 2,
        dibujos: 3,
        actividades: 9,
      ),
      categorias: const [
        (nombre: 'Familia', valor: 34),
        (nombre: 'Comida', valor: 28),
        (nombre: 'Acciones', valor: 22),
        (nombre: 'Emociones', valor: 18),
      ],
      pictos: const [
        (nombre: 'Manzana', valor: 24),
        (nombre: 'Quiero', valor: 18),
        (nombre: 'Feliz', valor: 12),
      ],
      apps: const [
        (nombre: 'YouTube', valor: 1200),
        (nombre: 'WhatsApp', valor: 600),
        (nombre: 'Galería', valor: 300),
      ],
      segundosPantalla: 3000,
      diasConApps: 10,
      animos: const {3: 5, 4: 3, 5: 2},
    );

Informe _vacio(Periodo periodo) => Informe(
      periodo: periodo,
      desde: _dia(periodo.dias - 1),
      hasta: _dia(0),
      diasConDatos: 0,
      serie: _serie(periodo.dias, (_) => 0),
      actual: const Totales(),
      anterior: const Totales(),
      categorias: const [],
      pictos: const [],
      apps: const [],
      segundosPantalla: 0,
      diasConApps: 0,
      animos: const {},
    );

Widget _app({
  required AppColors paleta,
  required Informe semana,
  required Informe mes,
  bool calma = false,
  bool conApps = true,
}) =>
    ProviderScope(
      overrides: [
        edicionDirectaProvider.overrideWithValue(conApps),
        informeProvider(Periodo.semana).overrideWith((ref) async => semana),
        informeProvider(Periodo.mes).overrideWith((ref) async => mes),
      ],
      child: MaterialApp(
        theme: buildBlueTalkTheme(paleta),
        home: Builder(
          builder: (context) {
            final pantalla = MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: calma),
              child: const InformesScreen(),
            );
            return calma
                ? ColorFiltered(
                    colorFilter: calmColorFilter,
                    child: pantalla,
                  )
                : pantalla;
          },
        ),
      ),
    );

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capturas claro, vacio, calma y oscuro', (tester) async {
    await tester.pumpWidget(_app(
      paleta: AppColors.celeste,
      semana: _lleno(Periodo.semana),
      mes: _lleno(Periodo.mes),
    ));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14c-claro');

    await tester.pumpWidget(_app(
      paleta: AppColors.celeste,
      semana: _vacio(Periodo.semana),
      mes: _vacio(Periodo.mes),
      conApps: false,
    ));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14c-vacio');

    await tester.pumpWidget(_app(
      paleta: AppColors.gris,
      semana: _lleno(Periodo.semana),
      mes: _lleno(Periodo.mes),
      calma: true,
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('¿De qué temas habló más?'),
      300,
      scrollable: find
          .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14c-calma');

    await tester.pumpWidget(_app(
      paleta: AppColors.oscuro,
      semana: _lleno(Periodo.semana),
      mes: _lleno(Periodo.mes),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mensual'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('¿Qué días usó la app?'),
      300,
      scrollable: find
          .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14c-oscuro');
  });
}
