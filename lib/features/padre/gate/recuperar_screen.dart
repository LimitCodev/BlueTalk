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

/// Recuperación del PIN olvidado (plan 11 §1.2; ampliada a petición del
/// dueño el 2026-10-19).
///
/// Dos caminos:
/// 1. **Código de recuperación** (no destructiva): si el dispositivo tiene
///    uno guardado, se valida contra su huella PBKDF2, se borra **solo** el
///    PIN y el gate queda en fase «crear»; el progreso, el horario y los
///    ajustes no se tocan. Comparte el bloqueo escalonado con el PIN.
/// 2. **BORRAR** (destructivo, literal del plan 11 §1.2): se borrarán el
///    progreso, el horario y los ajustes **de este dispositivo**, exige
///    escribir la palabra `BORRAR`, limpia **todas** las claves de
///    `SharedPreferences` (`prefs.clear()`) y vuelve a `/onboarding`.
///
/// La app sigue sin guardar el PIN ni el código en claro ni aceptar
/// respuestas de seguridad; ninguna huella sale del dispositivo.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final TextEditingController _palabra = TextEditingController();
  final TextEditingController _codigo = TextEditingController();

  /// true mientras se valida el código de recuperación (~PBKDF2).
  bool _verificando = false;

  /// Aviso de código de recuperación erróneo (null = sin aviso).
  String? _errorCodigo;

  @override
  void initState() {
    super.initState();
    // Reconstruye al teclear para habilitar cada botón con su texto exacto.
    _palabra.addListener(_alCambiar);
    _codigo.addListener(_alCambiar);
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _palabra.removeListener(_alCambiar);
    _codigo.removeListener(_alCambiar);
    _palabra.dispose();
    _codigo.dispose();
    super.dispose();
  }

  bool get _confirmado => _palabra.text == palabraDeConfirmacion;

  /// Recupera el acceso con el código de recuperación **sin borrar nada**:
  /// si es correcto, el gate queda en fase «crear» (PIN nuevo) y este
  /// camino se cierra; si no, se muestra el aviso en pantalla.
  Future<void> _recuperar() async {
    if (_verificando || _codigo.text.isEmpty) return;
    setState(() {
      _verificando = true;
      _errorCodigo = null;
    });
    try {
      final ok = await ref
          .read(gateProvider.notifier)
          .recuperarConCodigo(_codigo.text);
      if (!mounted) return;
      if (ok) {
        await Navigator.of(context).maybePop();
        return;
      }
      setState(() {
        _errorCodigo = ref.read(gateProvider).mensaje ??
            'Código de recuperación incorrecto.';
      });
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

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
    final puedeRecuperar = ref.read(gateProvider.notifier).tieneRecuperacion;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Recupera el acceso')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_open_outlined,
                  size: 56,
                  color: context.colores.primaryStrong,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recupera el acceso',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Si olvidaste tu código de 6 dígitos, tienes dos opciones.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (puedeRecuperar) ...[
                  // Opción 1: código de recuperación (no destructiva).
                  Text(
                    'Con tu código de recuperación',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No se borra nada: conservas el progreso, el horario y los '
                    'ajustes. Después creas un código nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codigo,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de recuperación',
                      hintText: 'XXXX-XXXX',
                    ),
                    onSubmitted: (_) => _recuperar(),
                  ),
                  if (_errorCodigo != null) ...[
                    const SizedBox(height: 8),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorCodigo!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                    onPressed: _codigo.text.isEmpty || _verificando
                        ? null
                        : _recuperar,
                    child: const Text('Recuperar sin borrar nada'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'O empieza de cero',
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Sin código de recuperación guardado: solo el borrado.
                  const Text(
                    'Esta app no guardó ningún código de recuperación en este '
                    'dispositivo. La única opción es borrar todo y empezar de '
                    'nuevo. Si más adelante generas uno (Control → Código de '
                    'recuperación), podrás recuperar el acceso sin borrar nada.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                Icon(
                  Icons.delete_outline,
                  size: 56,
                  color: context.colores.primaryStrong,
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
