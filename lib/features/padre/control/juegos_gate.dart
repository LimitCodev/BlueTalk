import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'control_parental.dart';

/// Guard de entrada a Juegos (plan 05 §4): horario bloqueado o tiempo
/// diario agotado. Muestra un aviso suave, nunca un pantallazo rojo.
///
/// Uso previsto del coordinador en `lib/app/router.dart`:
/// `JuegosGate(juegos: const JuegosScreen())` en la ruta `/home/aprender`.
class JuegosGate extends ConsumerWidget {
  const JuegosGate({super.key, required this.juegos});

  /// Pantalla de juegos a mostrar cuando está permitido.
  final Widget juegos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bloqueos = ref.watch(bloqueosProvider);
    if (bloqueos.juegos) return const _AvisoBloqueado();

    final limite = ref.watch(limiteJuegosProvider);
    return switch (limite) {
      // Si aún no hay datos calculados no se bloquea al niño.
      AsyncData(:final value) =>
        value.permitido ? juegos : _AvisoLimite(limite: value),
      AsyncError() => juegos,
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Panel de «se acabó el tiempo» con salida y ampliación.
class _AvisoLimite extends ConsumerWidget {
  const _AvisoLimite({required this.limite});

  final LimiteJuegos limite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PanelSuave(
      icono: Icons.hourglass_disabled_outlined,
      titulo: 'El tiempo de juegos de hoy terminó.',
      texto:
          'Has jugado ${limite.minutosUsados} de ${limite.minutosDisponibles} '
          'minutos de hoy.',
      botones: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () =>
              ref.read(limiteJuegosProvider.notifier).ampliar(),
          child: const Text(
            'Jugar ${LimiteJuegos.minutosDeExtension} minutos más',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => GoRouter.maybeOf(context)?.go('/home/comunicar'),
          child: const Text('Salir'),
        ),
      ],
    );
  }
}

/// Panel de sección bloqueada por un adulto.
class _AvisoBloqueado extends StatelessWidget {
  const _AvisoBloqueado();

  @override
  Widget build(BuildContext context) {
    return PanelSuave(
      icono: Icons.lock_outline,
      titulo: 'Los juegos están bloqueados por un adulto.',
      texto: 'Pide que te los desbloqueen desde la zona de adultos.',
      botones: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => GoRouter.maybeOf(context)?.go('/home/comunicar'),
          child: const Text('Salir'),
        ),
      ],
    );
  }
}

class PanelSuave extends StatelessWidget {
  const PanelSuave({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.botones,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final List<Widget> botones;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 40, color: AppColors.onWarning),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(texto, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ...botones,
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner suave para mostrar dentro de Juegos cuando quedan ≤5 minutos.
///
/// El coordinador puede insertarlo en la cabecera del home de Juegos; si no
/// hace falta, se omite y el corte se produce al salir y volver a entrar.
class AvisoTiempoJuegos extends ConsumerWidget {
  const AvisoTiempoJuegos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limite = ref.watch(limiteJuegosProvider).value;
    if (limite == null || !limite.cercaDelTope) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.onWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Te quedan ${limite.minutosRestantes} minutos de juegos hoy.',
              style: const TextStyle(color: AppColors.onWarning),
            ),
          ),
        ],
      ),
    );
  }
}
