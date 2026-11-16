import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../inicio/menu_centrado.dart';
import '../padre/gate/gate_controller.dart';
import 'guia_controller.dart';
import 'guia_globo.dart';
import 'guia_lista.dart';
import 'guia_medidor.dart';
import 'guia_posicion.dart';

/// Capa de la guía sobre toda la app (plan 14B §4). Se monta una vez en
/// `MaterialApp.router(builder:)`, encima del router.
class GuiaCapa extends ConsumerStatefulWidget {
  const GuiaCapa({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GuiaCapa> createState() => _GuiaCapaState();
}

class _GuiaCapaState extends ConsumerState<GuiaCapa>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        MedidorGuia<GuiaCapa> {
  var _confirmarSalto = false;

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

  void _irAlPaso(int? i) {
    _confirmarSalto = false;
    if (i == null) return;
    final paso = pasosGuia[i];
    final router = ref.read(routerProvider);
    final aqui = router.routerDelegate.currentConfiguration.uri.path;
    if (aqui != paso.ruta) router.go(paso.ruta);
    if (paso.tarjeta case final t?) {
      ref.read(menuCentradoProvider.notifier).centrar(t);
    }
    volverAMedir();
  }

  Future<void> _terminar() async {
    await ref.read(guiaProvider.notifier).terminar();
    ref.read(routerProvider).go('/padre');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(guiaProvider, (_, i) => _irAlPaso(i));
    final i = ref.watch(guiaProvider);
    // La app va siempre en la misma posición del árbol: abrir o cerrar la
    // guía no debe reconstruir el router.
    if (i == null) {
      return Stack(
        children: [ExcludeSemantics(excluding: false, child: widget.child)],
      );
    }
    final paso = pasosGuia[i];
    final ultimo = i == pasosGuia.length - 1;
    final conCodigo = ref.watch(gateProvider).fase == GateFase.pedir;
    final guia = ref.read(guiaProvider.notifier);
    return Stack(
      children: [
        ExcludeSemantics(child: widget.child),
        GuiaPosicion(
          hueco: rect?.inflate(8),
          borde: Theme.of(context).colorScheme.primary,
          globo: GuiaGlobo(
            paso: paso,
            numero: i + 1,
            texto: ultimo && conCodigo ? textoPadreConCodigo : paso.texto,
            onAtras: i == 0 ? null : guia.anterior,
            onSiguiente: ultimo ? _terminar : guia.siguiente,
            onSaltar: _confirmarSalto
                ? _terminar
                : () => setState(() => _confirmarSalto = true),
            confirmarSalto: _confirmarSalto,
            onCancelarSalto: () => setState(() => _confirmarSalto = false),
          ),
        ),
      ],
    );
  }
}
