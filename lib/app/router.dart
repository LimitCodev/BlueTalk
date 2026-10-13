import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/calm_mode.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_controller.dart';
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
                const _TabContent('Comunicar', 'Pictogramas y voz'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/aprender',
              pageBuilder: (context, state) => page(
                context,
                state,
                const _TabContent('Aprender', 'Juegos y cuentos'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/rutinas',
              pageBuilder: (context, state) => page(
                context,
                state,
                const _TabContent('Rutinas', 'Horario del día'),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home/ajustes',
              pageBuilder: (context, state) =>
                  page(context, state, const _AjustesTab()),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/padre',
        pageBuilder: (context, state) => page(
          context,
          state,
          const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Modo padre', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Se activará con tu PIN'),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
});

/// Contenido de una pestaña placeholder (el Scaffold lo pone el shell).
class _TabContent extends StatelessWidget {
  const _TabContent(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('$subtitle — próximamente'),
        ],
      ),
    );
  }
}

/// Ajustes (Ola 1): el interruptor del modo calma; el resto lo añade el paso 8.
class _AjustesTab extends StatelessWidget {
  const _AjustesTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [CalmModeToggle()],
    );
  }
}
