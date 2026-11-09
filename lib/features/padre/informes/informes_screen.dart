import 'package:flutter/material.dart';

import 'informe_modelo.dart';
import 'informe_vista.dart';

/// Informes para el docente, la madre, el padre o el apoderado: semanal
/// (resumen) y mensual (más detalle, gráficas y uso de otras apps).
class InformesScreen extends StatelessWidget {
  const InformesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Informes'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Semanal'), Tab(text: 'Mensual')],
          ),
        ),
        body: const TabBarView(
          children: [
            InformeVista(periodo: Periodo.semana),
            InformeVista(periodo: Periodo.mes),
          ],
        ),
      ),
    );
  }
}

/// Entrada desde el Resumen del modo padre.
class AccesoInformes extends StatelessWidget {
  const AccesoInformes({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InformesScreen()),
        ),
        icon: const Icon(Icons.summarize_outlined),
        label: const Text('Informes semanal y mensual'),
      ),
    );
  }
}
