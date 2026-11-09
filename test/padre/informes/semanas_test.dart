import 'package:bluetalk/features/padre/informes/informe_modelo.dart';
import 'package:bluetalk/features/padre/informes/semanas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<PuntoDia> serie(int n, {int? pantallaDesde}) => [
        for (var i = 0; i < n; i++)
          (
            dia: DateTime(2026, 10, 10 + i),
            pictos: 1,
            segundosJuego: 60,
            segundosPantalla: pantallaDesde != null && i >= pantallaDesde ? 100 : null,
          ),
      ];

  test('30 días son 4 semanas y un tramo de 2 días', () {
    final s = porSemanas(serie(30));
    expect(s.map((x) => x.pictos), [7, 7, 7, 7, 2]);
    expect((s.first.desde, s.first.hasta), (DateTime(2026, 10, 10), DateTime(2026, 10, 16)));
    expect(s.last.segundosJuego, 120);
  });

  test('pantalla: null sin datos; suma solo los días con datos', () {
    final s = porSemanas(serie(14, pantallaDesde: 10));
    expect(s.first.segundosPantalla, isNull);
    expect(s.last.segundosPantalla, 400);
  });
}
