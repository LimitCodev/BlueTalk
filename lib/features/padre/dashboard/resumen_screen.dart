import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import '../diagnostico/observaciones.dart';
import '../informes/informes_screen.dart';
import 'metricas.dart';
import 'resumen_graficos.dart';
import 'resumen_tarjetas.dart';
import 'uso_telefono_resumen.dart';

/// Resumen del padre: gráficos, datos locales y observaciones con
/// disclaimer (plan 14C §4).
class ResumenScreen extends ConsumerWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = ref.watch(metricasProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const AccesoInformes(),
        switch (metricas) {
          AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResumenGraficos(metricas: value),
                ResumenTarjetas(metricas: value),
              ],
            ),
          AsyncError() => _SinDatos(
              onReintentar: () => ref.invalidate(metricasProvider),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
        if (ref.watch(edicionDirectaProvider)) const UsoTelefonoResumen(),
        const ObservacionesSection(),
      ],
    );
  }
}

class _SinDatos extends StatelessWidget {
  const _SinDatos({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('No se pudieron cargar las métricas.'),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
