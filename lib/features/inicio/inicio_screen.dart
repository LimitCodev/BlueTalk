import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/atras_shell.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/calm_mode.dart';
import '../../core/widgets/logo_bluetalk.dart';
import '../onboarding/profile_controller.dart';
import '../guia/guia_controller.dart';
import '../guia/guia_objetivos.dart';
import '../guia/guia_pasos.dart';
import 'inicio_lista.dart';
import 'menu_carrusel.dart';

/// Menú principal tras el nombre (plan 14A), como `/menu` de la web:
/// saludo y botones grandes que llevan a cada sección.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apodo = ref.watch(profileProvider)?.nickname.trim() ?? '';
    final calm = ref.watch(calmModeProvider);
    final texto = Theme.of(context).textTheme;
    // Primera vez en el menú: empieza la guía de la mascota (plan 14B).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(guiaProvider.notifier).iniciarSiFalta(),
    );
    return PopScope(
      canPop: false,
      // El menú es el único punto de salida de la app (plan 14 §2),
      // salvo con el kiosko del plan 12.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || guiaAtras(ref)) return;
        if (ref.read(saleConAtrasProvider)) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // Sin campos de texto: el teclado no debe encoger el carrusel.
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          toolbarHeight: 72,
          title: Row(
            children: [
              const LogoBluetalkWordmark(height: 28, pill: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apodo.isEmpty ? '¡Hola! 👋' : '¡Hola, $apodo! 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '¿Qué quieres hacer hoy?',
                      style: texto.bodyMedium?.copyWith(
                        color: context.colores.onHeader,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.contrast),
              tooltip: 'Modo calma',
              onPressed: () => ref.read(calmModeProvider.notifier).set(!calm),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: MediaQuery.accessibleNavigationOf(context)
                  ? const InicioLista()
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: GuiaAncla(
                        objetivo: GuiaObjetivo.menuCarrusel,
                        child: MenuCarrusel(),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
