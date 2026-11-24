import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guia_controller.dart';

/// Arranca la guía de la mascota una sola vez al abrir el menú.
///
/// Antes el `addPostFrameCallback` se programaba en cada build de la
/// pantalla; ahora vive en `initState` y no cuesta nada al reconstruir.
class GuiaArranque extends ConsumerStatefulWidget {
  const GuiaArranque({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GuiaArranque> createState() => _GuiaArranqueState();
}

class _GuiaArranqueState extends ConsumerState<GuiaArranque> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(guiaProvider.notifier).iniciarSiFalta();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
