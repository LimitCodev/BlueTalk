import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'proteccion_controller.dart';

/// Casilla de la protección contra desinstalación.
///
/// Se lee sola de Android y se vuelve a leer al volver de las pantallas
/// del sistema, porque activar el administrador pasa por una pantalla
/// ajena a la app. La fila entera es la zona táctil (≥48dp), igual que el
/// resto de la pantalla de control.
class ProteccionTile extends ConsumerStatefulWidget {
  const ProteccionTile({super.key});

  @override
  ConsumerState<ProteccionTile> createState() => _ProteccionTileState();
}

class _ProteccionTileState extends ConsumerState<ProteccionTile>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Vuelve de la pantalla de Android: el estado puede haber cambiado.
    if (state == AppLifecycleState.resumed) ref.invalidate(proteccionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(proteccionProvider).value;
    final activo = estado?.activo ?? false;

    return ListTile(
      leading: const Icon(Icons.phonelink_lock_outlined),
      title: const Text('Protección contra desinstalación'),
      subtitle: Text(
        activo
            ? 'Activa. Desinstalar BlueTalk exige antes pasar por una '
                'pantalla de Android.'
            : 'Sin activar. Desde Ajustes del teléfono se podría '
                'desinstalar la app.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => activo ? _confirmarDesactivar() : _activar(),
    );
  }

  Future<void> _activar() async {
    await ref.read(proteccionGatewayProvider).pedirActivacion();
    // El sistema tarda en volver; la relectura la dispara el ciclo de vida.
    ref.invalidate(proteccionProvider);
  }

  Future<void> _confirmarDesactivar() async {
    final ahora = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Quitar la protección?'),
        content: const Text(
          'Sin ella, cualquiera con el teléfono podría desinstalar BlueTalk '
          'desde Ajustes. El PIN del adulto seguirá pidiéndose para entrar '
          'aquí.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Dejarla puesta'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitarla'),
          ),
        ],
      ),
    );
    if (ahora != true || !mounted) return;
    await ref.read(proteccionGatewayProvider).desactivar();
    ref.invalidate(proteccionProvider);
  }
}
