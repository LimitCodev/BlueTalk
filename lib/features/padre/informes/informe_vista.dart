import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'informe_modelo.dart';
import 'informe_secciones.dart';
import 'informe_semanas.dart';
import 'informe_texto.dart';
import 'informe_uso_telefono.dart';
import 'informes_providers.dart';

/// Un informe (semanal o mensual) con sus secciones y «Copiar informe».
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
            SeccionComunicacion(informe: value),
            SeccionJuegoYAnimo(informe: value),
            SeccionUsoTelefono(informe: value),
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
