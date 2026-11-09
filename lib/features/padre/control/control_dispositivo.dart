import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import '../../../core/widgets/section_header.dart';
import '../filtro_web/filtro_web_controller.dart';
import '../filtro_web/filtro_web_screen.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../monitoreo/uso_telefono_screen.dart';

/// Filtro de páginas y tiempo por app: solo en la edición directa.
class SeccionesDispositivo extends ConsumerWidget {
  const SeccionesDispositivo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(edicionDirectaProvider)) return const SizedBox.shrink();
    final filtro = ref.watch(filtroWebProvider);
    final usoConcedido = ref.watch(permisoUsoProvider).value ?? false;

    return Column(
      children: [
        const SectionHeader('Protección en internet'),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Filtro de páginas'),
          subtitle: Text(
            filtro.activo
                ? 'Activo: bloquea los sitios elegidos.'
                : 'Apagado: los sitios no se bloquean.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const FiltroWebScreen()),
          ),
        ),
        const SectionHeader('Diagnóstico de uso'),
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: const Text('Tiempo por app'),
          subtitle: Text(
            usoConcedido
                ? 'Revisa cuánto tiempo estuvo abierta cada app.'
                : 'Falta el permiso «Acceso al uso» de Android.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const UsoTelefonoScreen()),
          ),
        ),
      ],
    );
  }
}
