import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import '../../salud/salud_providers.dart';
import '../monitoreo/uso_telefono_model.dart';
import 'grafica_columnas.dart';
import 'informe_modelo.dart';
import 'informe_texto.dart';
import 'lista_ranking.dart';

class CabeceraInforme extends StatelessWidget {
  const CabeceraInforme({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final i = informe;
    return ListTile(
      title: Text('Del ${fechaLarga(i.desde)} al ${fechaLarga(i.hasta)}'),
      subtitle: Text('Orientativo. No es un diagnóstico.\n'
          'BlueTalk se usó ${i.diasConDatos} de ${i.periodo.dias} días.'),
    );
  }
}

class SeccionComunicacion extends StatelessWidget {
  const SeccionComunicacion({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final i = informe;
    final serie = [for (final p in i.serie) p.pictos];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Comunicación'),
        Text('Pictogramas tocados: ${i.actual.pictos} '
            '(periodo anterior: ${i.anterior.pictos}). '
            'Distintos: ${i.actual.pictosDistintos}.'),
        const SizedBox(height: 8),
        GraficaColumnas(
          valores: serie,
          descripcion: 'Pictogramas por día, del ${fechaLarga(i.desde)} al '
              '${fechaLarga(i.hasta)}: ${serie.join(', ')}.',
        ),
        ListaRanking(titulo: 'Más usados', ranking: i.pictos),
        ListaRanking(titulo: 'Categorías', ranking: i.categorias),
      ]),
    );
  }
}

class SeccionJuegoYAnimo extends StatelessWidget {
  const SeccionJuegoYAnimo({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final a = informe.actual;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Juegos y rutinas'),
        Text('Tiempo de juego: ${formatearDuracion(a.segundosJuego)} '
            '(${a.sesionesJuego} sesiones). Cuentos: ${a.cuentos}. '
            'Dibujos: ${a.dibujos}. Actividades hechas: ${a.actividades}.'),
        const SectionHeader('Ánimo'),
        if (informe.animos.isEmpty) const Text('Sin check-ins en este periodo.'),
        for (final o in opcionesEmocion.reversed)
          if (informe.animos[o.mood] case final n?) Text('${o.label}: $n'),
      ]),
    );
  }
}
