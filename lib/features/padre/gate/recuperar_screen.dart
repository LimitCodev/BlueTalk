import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../rutinas/recordatorios/recordatorios_controller.dart';
import '../../rutinas/rutinas_providers.dart';
import '../../ajustes/settings_controller.dart';
import '../../onboarding/profile_controller.dart';
import '../legal/legal_controller.dart';
import '../padre_controller.dart';
import 'gate_controller.dart';

/// Palabra exacta que confirma el borrado (plan 11 §1.2).
const palabraDeConfirmacion = 'BORRAR';

/// Recuperación del PIN olvidado (plan 11 §1.2).
///
/// Literal del plan: explica que se borrarán el progreso, el horario y los
/// ajustes **de este dispositivo**, exige escribir la palabra `BORRAR`,
/// limpia **todas** las claves de `SharedPreferences` (`prefs.clear()`) y
/// vuelve a `/onboarding`.
///
/// No existe otra forma de entrar sin el código: la app no guarda el PIN ni
/// acepta respuestas de seguridad, y su huella no sale del dispositivo.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final TextEditingController _palabra = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reconstruye al teclear para habilitar el botón con la palabra exacta.
    _palabra.addListener(_alCambiar);
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _palabra.removeListener(_alCambiar);
    _palabra.dispose();
    super.dispose();
  }

  bool get _confirmado => _palabra.text == palabraDeConfirmacion;

  Future<void> _borrar() async {
    if (!_confirmado) return;
    // Los avisos ya programados apuntan al horario viejo: se cancelan
    // antes de borrar (plan 11 §1.2), que no llegue ningún aviso de
    // datos que ya no existen.
    await ref.read(recordatoriosProvider.notifier).cancelarTodoProgramado();
    // Se borra todo lo guardado en este dispositivo: PIN, progreso,
    // horario, ajustes y consentimientos.
    await ref.read(sharedPreferencesProvider).clear();
    // Los providers memorizan datos que ya no existen: se recalculan.
    ref
      ..invalidate(gateProvider)
      ..invalidate(legalProvider)
      ..invalidate(padreProvider)
      ..invalidate(settingsProvider)
      ..invalidate(horarioProvider)
      ..invalidate(profileProvider)
      ..invalidate(recordatoriosProvider);
    if (!mounted) return;
    // Sin un router por debajo (pantalla suelta en tests) no hay adónde
    // navegar: los datos ya están borrados, que es lo esencial.
    GoRouter.maybeOf(context)?.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrar el código y empezar de nuevo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 56,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(height: 16),
                Text(
                  'Se va a borrar todo lo de este dispositivo',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si borras el código, se borran también el progreso, el '
                  'horario y los ajustes guardados en este dispositivo. '
                  'No se puede deshacer. En otros dispositivos no se borra '
                  'nada.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _palabra,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Escribe BORRAR con mayúsculas',
                  ),
                  onSubmitted: (_) => _borrar(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style:
                      FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                  onPressed: _confirmado ? _borrar : null,
                  child: const Text('Borrar todo y empezar de nuevo'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
