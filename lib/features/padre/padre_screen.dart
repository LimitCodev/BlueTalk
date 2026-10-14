import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'control/control_screen.dart';
import 'dashboard/resumen_screen.dart';
import 'gate/gate_screen.dart';
import 'legal/legal_controller.dart';
import 'legal/legal_screen.dart';
import 'padre_controller.dart';
import 'salud_padre/salud_screen.dart';

/// Pantalla raíz de la zona de adultos (ruta `/padre`).
///
/// Autocontenida con Scaffold propio y navegación interna
/// (gate → resumen → control → salud → legal), al estilo de `JuegosScreen`:
/// el cambio que debe hacer el coordinador en `lib/app/router.dart` es
/// sustituir el placeholder de `/padre` por `const PadreScreen()` y nada más.
class PadreScreen extends ConsumerStatefulWidget {
  const PadreScreen({super.key, this.onSalir});

  /// Sale del modo padre. Si no se pasa, la ruta raíz decide.
  final VoidCallback? onSalir;

  @override
  ConsumerState<PadreScreen> createState() => _PadreScreenState();
}

class _PadreScreenState extends ConsumerState<PadreScreen> {
  static const _destinos = [
    (
      vista: PadreVista.resumen,
      label: 'Resumen',
      icono: Icons.insights_outlined,
      activo: Icons.insights,
    ),
    (
      vista: PadreVista.control,
      label: 'Control',
      icono: Icons.tune_outlined,
      activo: Icons.tune,
    ),
    (
      vista: PadreVista.salud,
      label: 'Salud',
      icono: Icons.favorite_outline,
      activo: Icons.favorite,
    ),
    (
      vista: PadreVista.legal,
      label: 'Legal',
      icono: Icons.description_outlined,
      activo: Icons.description,
    ),
  ];

  void _salir() {
    if (ref.read(legalProvider) != null) {
      ref.read(padreProvider.notifier).cerrarSesion();
    }
    final onSalir = widget.onSalir;
    if (onSalir != null) {
      onSalir();
      return;
    }
    GoRouter.maybeOf(context)?.go('/home/ajustes');
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(padreProvider);
    final aceptado = ref.watch(legalProvider) != null;
    final enSesion = aceptado && vista != PadreVista.gate;
    final indice = _destinos.indexWhere((destino) => destino.vista == vista);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo padre'),
        actions: [
          if (enSesion)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Cerrar sesión',
              onPressed: () => ref.read(padreProvider.notifier).cerrarSesion(),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Salir del modo padre',
            onPressed: _salir,
          ),
        ],
      ),
      body: switch (vista) {
        PadreVista.legal => LegalScreen(onSalir: _salir),
        PadreVista.gate => const GateScreen(),
        PadreVista.resumen => const ResumenScreen(),
        PadreVista.control => const ControlScreen(),
        PadreVista.salud => const SaludPadreScreen(),
      },
      bottomNavigationBar: enSesion
          ? NavigationBar(
              selectedIndex: indice < 0 ? 0 : indice,
              onDestinationSelected: (i) =>
                  ref.read(padreProvider.notifier).irA(_destinos[i].vista),
              destinations: [
                for (final destino in _destinos)
                  NavigationDestination(
                    label: destino.label,
                    icon: Icon(destino.icono),
                    selectedIcon: Icon(destino.activo),
                  ),
              ],
            )
          : null,
    );
  }
}
