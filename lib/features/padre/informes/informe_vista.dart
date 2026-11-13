import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import 'graficos_animo.dart';
import 'graficos_calendario.dart';
import 'graficos_comparacion.dart';
import 'graficos_dias.dart';
import 'graficos_serie.dart';
import 'graficos_temas.dart';
import 'informe_modelo.dart';
import 'informe_secciones.dart';
import 'informe_semanas.dart';
import 'informe_texto.dart';
import 'informe_uso_telefono.dart';
import 'informes_providers.dart';

/// Un informe (semanal o mensual) con sus gráficos y «Copiar informe».
class InformeVista extends ConsumerWidget {
  const InformeVista({super.key, required this.periodo});

  final Periodo periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(informeProvider(periodo))) {
      AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            CabeceraInforme(informe: value),
            SeccionComparacion(informe: value),
            SeccionDiasUso(informe: value),
            SeccionMedidor(informe: value),
            SeccionSerie(informe: value),
            if (periodo == Periodo.mes) SeccionCalendario(informe: value),
            SeccionCategorias(informe: value),
            SeccionAnimo(informe: value),
            SeccionJuego(informe: value),
            if (ref.watch(edicionDirectaProvider)) SeccionApps(informe: value),
            SeccionPalabras(informe: value),
            if (periodo == Periodo.mes) SeccionPorSemana(informe: value),
            _BotonCopiar(informe: value),
          ],
        ),
      AsyncError() => Center(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.invalidate(informeProvider(periodo)),
            child: const Text('No se pudo calcular. Reintentar'),
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _BotonCopiar extends StatelessWidget {
  const _BotonCopiar({required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () async {
          await Clipboard.setData(
            ClipboardData(text: informeComoTexto(informe)),
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Informe copiado. Pégalo en WhatsApp o en un correo.'),
          ));
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copiar informe'),
      ),
    );
  }
}
