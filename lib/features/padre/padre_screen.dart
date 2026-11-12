import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'control/control_screen.dart';
import 'dashboard/resumen_screen.dart';
import 'gate/gate_screen.dart';
import 'legal/legal_controller.dart';
import 'legal/legal_screen.dart';
import 'padre_controller.dart';
import 'permisos/permisos_controller.dart';
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

class _PadreScreenState extends ConsumerState<PadreScreen>
    with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Caché de permisos: el panel ya no depende de ellos, pero el
    // asistente debe enseñar el estado real al abrirse. Se relee al entrar
    // en la zona y al volver de una pantalla de Android.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => mounted ? ref.invalidate(permisosProvider) : null,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Volvemos de una pantalla de Android: alguien pudo conceder o
    // revocar un permiso con la app en segundo plano.
    if (state == AppLifecycleState.resumed) ref.invalidate(permisosProvider);
  }

  void _salir() {
    if (ref.read(legalProvider) != null) {
      ref.read(padreProvider.notifier).cerrarSesion();
    }
    final onSalir = widget.onSalir;
    if (onSalir != null) {
      onSalir();
      return;
    }
    GoRouter.maybeOf(context)?.go('/inicio');
  }

  @override
  Widget build(BuildContext context) {
    final vista = ref.watch(padreProvider);
    final aceptado = ref.watch(legalProvider) != null;
    final enSesion = aceptado && vista != PadreVista.gate;
    final indice = _destinos.indexWhere((destino) => destino.vista == vista);

    // P0-4 de Play: ningún permiso es obligatorio. Tras aceptar la legal,
    // el panel se enseña siempre; los permisos se explican en Control y se
    // conceden solo si el adulto quiere.

    // Fila 4 del plan 13 P1 (corregido tras la revisión de la etapa A): el
    // Atrás nunca mata el modo padre. Con una subpantalla empujada (p. ej.
    // recuperación del PIN) la cierra Navigator; desde una pestaña que no
    // es el panel se vuelve al panel; y desde el panel (o el gate) el
    // Atrás sale como «Salir del modo padre», al menú (plan 14 §2).
    // Si la legal aún no se aceptó, se sale siempre.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final vista = ref.read(padreProvider);
        final aceptado = ref.read(legalProvider) != null;
        if (aceptado &&
            (vista == PadreVista.control ||
                vista == PadreVista.salud ||
                vista == PadreVista.legal)) {
          ref.read(padreProvider.notifier).irA(PadreVista.resumen);
          return;
        }
        _salir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modo padre'),
          actions: [
            // Sin candado en la cabecera: «Salir del modo padre» (la X)
            // ya cierra la sesión y re-bloquea el gate al mismo tiempo;
            // un candado que solo volvía al PIN dentro del propio modo
            // padre confundía (queja del dueño, 2026-10-19).
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
      ),
    );
  }
}
