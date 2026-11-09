import '../../salud/salud_providers.dart';
import '../monitoreo/uso_telefono_model.dart';
import 'informe_modelo.dart';

const _meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
    'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

String fechaLarga(DateTime f) => '${f.day} de ${_meses[f.month - 1]} de ${f.year}';

String _lista(Ranking r, String Function(int) valor) =>
    r.isEmpty ? 'sin datos' : r.map((e) => '${e.nombre} (${valor(e.valor)})').join(', ');

/// Texto plano para copiar y pegar (WhatsApp, correo). Sin el nombre del
/// niño ni datos que lo identifiquen: lo comparte la persona adulta.
String informeComoTexto(Informe i) {
  final a = i.actual;
  final animos = [
    for (final o in opcionesEmocion.reversed)
      if (i.animos[o.mood] case final n?) '${o.label}: $n',
  ];
  return [
    'Informe ${i.periodo.nombre} de BlueTalk',
    'Del ${fechaLarga(i.desde)} al ${fechaLarga(i.hasta)}',
    'Orientativo. No es un diagnóstico.',
    '',
    'Comunicación',
    '- Pictogramas tocados: ${a.pictos} (periodo anterior: ${i.anterior.pictos})',
    '- Pictogramas distintos: ${a.pictosDistintos}',
    '- Más usados: ${_lista(i.pictos, (v) => '$v')}',
    '- Categorías: ${_lista(i.categorias, (v) => '$v')}',
    '',
    'Juegos y rutinas',
    '- Tiempo de juego: ${formatearDuracion(a.segundosJuego)} '
        'en ${a.sesionesJuego} ${a.sesionesJuego == 1 ? 'sesión' : 'sesiones'}',
    '- Cuentos terminados: ${a.cuentos}. Dibujos guardados: ${a.dibujos}',
    '- Actividades del horario hechas: ${a.actividades}',
    '',
    'Ánimo (check-ins)',
    '- ${animos.isEmpty ? 'sin check-ins' : animos.join('. ')}',
    if (i.diasConApps > 0) ...[
      '',
      'Uso del teléfono (otras apps)',
      '- Tiempo total: ${formatearDuracion(i.segundosPantalla)} '
          '(${i.diasConApps} de ${i.periodo.dias} días con datos)',
      '- Más usadas: ${_lista(i.apps, formatearDuracion)}',
    ],
    '',
    'BlueTalk usó ${i.diasConDatos} de ${i.periodo.dias} días. '
        'Calculado en el teléfono; BlueTalk no envía estos datos.',
  ].join('\n');
}
