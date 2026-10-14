import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import '../features/ajustes/ajustes_screen.dart';
import '../features/comunicador/comunicador_screen.dart';
import '../features/juegos/juegos_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_controller.dart';
import '../features/padre/control/juegos_gate.dart';
import '../features/padre/padre_screen.dart';
import '../features/rutinas/rutinas_screen.dart';
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

  // Si ya hay perfil guardado, arranca directo en el home (sin onboarding).
  final hasProfile = ref.read(profileProvider) != null;

  return GoRouter(
    initialLocation: hasProfile ? '/home/comunicar' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => page(
          context,
          state,
          const OnboardingScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/comunicar',
              pageBuilder: (context, state) => page(
                context,
                state,
                const ComunicadorScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/aprender',
              pageBuilder: (context, state) => page(
                context,
                state,
                const JuegosGate(juegos: JuegosScreen()),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/rutinas',
              pageBuilder: (context, state) => page(
                context,
                state,
                const RutinasScreen(),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/ajustes',
              pageBuilder: (context, state) =>
                  page(context, state, const AjustesScreen()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/padre',
        pageBuilder: (context, state) => page(
          context,
          state,
          const PadreScreen(),
        ),
      ),
    ],
  );
});
