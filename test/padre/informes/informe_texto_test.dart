import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/informes/construir_informe.dart';
import 'package:bluetalk/features/padre/informes/informe_modelo.dart';
import 'package:bluetalk/features/padre/informes/informe_texto.dart';
import 'package:bluetalk/features/padre/informes/resumen_dia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final hasta = DateTime(2026, 11, 8);

  test('texto literal con fechas, aviso y comparación', () {
    final texto = informeComoTexto(construirInforme(
      periodo: Periodo.semana,
      hasta: hasta,
      resumenes: const [
        ResumenDia(dia: '2026-11-03', pictos: 3, pictosUsados: {'agua': 3}, segundosJuego: 300, sesionesJuego: 1),
      ],
      animos: [MoodEntry(id: 'x', date: DateTime(2026, 11, 3), mood: 5)],
      nombres: const {'agua': 'Agua'},
    ));
    expect(texto, startsWith('Informe semanal de BlueTalk\nDel 2 de noviembre de 2026 al 8 de noviembre de 2026'));
    expect(texto, contains('Orientativo. No es un diagnóstico.'));
    expect(texto, contains('- Pictogramas tocados: 3 (periodo anterior: 0)'));
    expect(texto, contains('Agua (3)'));
    expect(texto, contains('5 min en 1 sesión'));
    expect(texto, contains('Feliz: 1'));
    expect(texto, contains('BlueTalk usó 1 de 7 días'));
    expect(texto, isNot(contains('Uso del teléfono')), reason: 'sin datos de apps no se inventa la sección');
  });

  test('con datos de apps añade la sección de uso del teléfono', () {
    final texto = informeComoTexto(construirInforme(
      periodo: Periodo.mes,
      hasta: hasta,
      resumenes: const [
        ResumenDia(dia: '2026-11-08', apps: UsoAppsDia(totalSegundos: 3600, apps: {'yt': (nombre: 'YouTube', segundos: 3600)})),
      ],
    ));
    expect(texto, contains('Informe mensual'));
    expect(texto, contains('- Tiempo total: 1 h (1 de 30 días con datos)'));
    expect(texto, contains('YouTube (1 h)'));
  });
}
