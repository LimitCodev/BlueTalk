import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/informes/construir_informe.dart';
import 'package:bluetalk/features/padre/informes/informe_modelo.dart';
import 'package:bluetalk/features/padre/informes/resumen_dia.dart';
import 'package:flutter_test/flutter_test.dart';

ResumenDia dia(String d, {int pictos = 0, Map<String, int> u = const {}, int juego = 0, UsoAppsDia? apps}) =>
    ResumenDia(dia: d, pictos: pictos, pictosUsados: u, categorias: {'comida': pictos}, segundosJuego: juego, sesionesJuego: juego > 0 ? 1 : 0, apps: apps);

UsoAppsDia apps(Map<String, int> s) => UsoAppsDia(
      totalSegundos: s.values.fold(0, (a, b) => a + b),
      apps: {for (final e in s.entries) e.key: (nombre: e.key.toUpperCase(), segundos: e.value)},
    );

void main() {
  final domingo = DateTime(2026, 11, 8, 20);

  test('semana: serie de 7 días, totales y comparación con la anterior', () {
    final i = construirInforme(
      periodo: Periodo.semana,
      hasta: domingo,
      resumenes: [
        dia('2026-11-02', pictos: 4, u: {'agua': 3, 'pan': 1}, juego: 120),
        dia('2026-11-08', pictos: 2, u: {'agua': 2}),
        dia('2026-10-30', pictos: 10), // semana anterior
      ],
      nombres: {'agua': 'Agua', 'comida': 'Comida'},
    );
    expect((i.desde, i.hasta), (DateTime(2026, 11, 2), DateTime(2026, 11, 8)));
    expect(i.serie, hasLength(7));
    expect(i.serie.first.pictos, 4);
    expect((i.actual.pictos, i.actual.pictosDistintos, i.actual.segundosJuego), (6, 2, 120));
    expect(i.anterior.pictos, 10);
    expect(i.diasConDatos, 2);
    expect(i.pictos.first, (nombre: 'Agua', valor: 5));
    expect(i.categorias.single, (nombre: 'Comida', valor: 6));
  });

  test('mes: suma apps de los días con datos y no inventa los que faltan', () {
    final i = construirInforme(
      periodo: Periodo.mes,
      hasta: domingo,
      resumenes: [
        dia('2026-11-07', apps: apps({'yt': 600, 'cam': 60})),
        dia('2026-11-08', apps: apps({'yt': 300})),
        dia('2026-11-06'),
      ],
    );
    expect(i.serie, hasLength(30));
    expect((i.diasConApps, i.segundosPantalla), (2, 960));
    expect(i.apps.first, (nombre: 'YT', valor: 900));
    expect(i.serie.where((p) => p.segundosPantalla == null), hasLength(28));
  });

  test('ánimos: solo los del periodo, contados por valor', () {
    MoodEntry m(DateTime d, int v) => MoodEntry(id: '$d$v', date: d, mood: v);
    final i = construirInforme(
      periodo: Periodo.semana,
      hasta: domingo,
      resumenes: const [],
      animos: [m(DateTime(2026, 11, 3), 5), m(DateTime(2026, 11, 8, 9), 5), m(DateTime(2026, 11, 4), 1), m(DateTime(2026, 10, 1), 2)],
    );
    expect(i.animos, {5: 2, 1: 1});
    expect(i.diasConDatos, 0);
  });
}
