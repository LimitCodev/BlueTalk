import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_controller.dart';
import '../features/padre/padre_screen.dart';
import 'router_ramas.dart';
import 'shell.dart';

/// Router raíz: una sola instancia (recargarlo perdería la ruta actual).
///
/// Las rutas placeholder permiten que los agentes de la Ola 2 solo registren
/// su pantalla real dentro de su carpeta dueña.
final routerProvider = Provider<GoRouter>((ref) {
  Page<Object?> page(BuildContext context, GoRouterState state, Widget child) {
    if (ref.read(calmModeProvider)) {
      // Modo calma: duración 0 → la ruta aparece sin transición (plan 00 §4).
      return CustomTransitionPage<Object?>(
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        child: child,
      );
    }
    return MaterialPage<Object?>(child: child);
  }

  // Si ya hay perfil guardado, arranca directo en el menú (sin onboarding).
  final hasProfile = ref.read(profileProvider) != null;

  return GoRouter(
    initialLocation: hasProfile ? '/inicio' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            page(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/inicio',
        pageBuilder: (context, state) =>
            page(context, state, const InicioScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: ramasShell(page),
      ),
      GoRoute(
        path: '/padre',
        pageBuilder: (context, state) =>
            page(context, state, const PadreScreen()),
      ),
    ],
  );
});
