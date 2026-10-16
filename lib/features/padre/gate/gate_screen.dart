import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../padre_controller.dart';
import 'biometria.dart';
import 'gate_controller.dart';
import 'recuperar_screen.dart';

/// Gate de la zona de adultos: crear el PIN, confirmarlo o pedirlo.
///
/// Literal del plan 05 §1 para el error (la web decía lo mismo):
/// «Código incorrecto, inténtalo de nuevo.»
class GateScreen extends ConsumerStatefulWidget {
  const GateScreen({super.key});

  @override
  ConsumerState<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends ConsumerState<GateScreen> {
  final TextEditingController _pin = TextEditingController();

  /// Primer PIN tecleado, solo en memoria mientras se confirma.
  String? _primero;

  @override
  void initState() {
    super.initState();
    // Reconstruye al teclear para habilitar el botón al llegar a la
    // longitud del código (6 dígitos, o los 4 de un PIN antiguo).
    _pin.addListener(_alCambiar);
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _pin.removeListener(_alCambiar);
    _pin.dispose();
    super.dispose();
  }

  void _limpiar() => _pin.clear();

  /// Tras validar, pasa el control al padre de la pantalla raíz.
  void _entrarSiDesbloqueado() {
    // Tras un await la pantalla pudo haberse ido (revisión fase 1).
    if (!mounted) return;
    if (!ref.read(gateProvider).desbloqueado) return;
    _limpiar();
    ref.read(padreProvider.notifier).entrar();
  }

  /// true mientras dura la verificación (~PBKDF2): con los botones
  /// apagados, un doble toque no cuenta dos fallos seguidos.
  bool _verificando = false;

  Future<void> _intentar() async {
    if (_verificando) return;
    setState(() => _verificando = true);
    try {
      await ref.read(gateProvider.notifier).intentar(_pin.text);
      _entrarSiDesbloqueado();
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _intentarBiometria() async {
    if (_verificando) return;
    setState(() => _verificando = true);
    try {
      await ref.read(gateProvider.notifier).intentarBiometria();
      _entrarSiDesbloqueado();
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(gateProvider);
    final controlador = ref.read(gateProvider.notifier);

    return switch (estado.fase) {
      GateFase.crear => _CrearView(
          controlador: _pin,
          longitud: estado.longitud,
          mensaje: estado.mensaje,
          onContinuar: () {
            _primero = _pin.text;
            _limpiar();
            controlador.pasarAConfirmar();
          },
        ),
      GateFase.confirmar => _ConfirmarView(
          controlador: _pin,
          longitud: estado.longitud,
          mensaje: estado.mensaje,
          onConfirmar: () async {
            final texto = _pin.text;
            _limpiar();
            if (texto != _primero) {
              _primero = null;
              controlador.reiniciarCreacion(
                'Los códigos no coinciden. Intenta de nuevo.',
              );
              return;
            }
            _primero = null;
            await controlador.crearPin(texto);
            _entrarSiDesbloqueado();
          },
          onVolver: () {
            _primero = null;
            _limpiar();
            controlador.reiniciarCreacion('Empieza de nuevo.');
          },
        ),
      GateFase.pedir => _PedirView(
          estado: estado,
          controlador: _pin,
          verificando: _verificando,
          onEntrar: _intentar,
          onBiometria: _intentarBiometria,
          onOlvide: () {
            _limpiar();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RecuperarScreen(),
              ),
            );
          },
        ),
    };
  }
}

/// Columna base con retrato y título literal.
class _ColumnaGate extends StatelessWidget {
  const _ColumnaGate({
    required this.titulo,
    required this.explicacion,
    required this.hijos,
  });

  final String titulo;
  final String explicacion;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: context.colores.primaryStrong,
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(explicacion, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ...hijos,
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo numérico y oculto con la longitud del código en curso.
Widget _campoPin(
  TextEditingController controlador, {
  required int longitud,
  VoidCallback? onEnviado,
}) {
  return TextField(
    controller: controlador,
    autofocus: true,
    obscureText: true,
    maxLength: longitud,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: 'Código de $longitud dígitos',
      counterText: '',
    ),
    onSubmitted: (_) => onEnviado?.call(),
  );
}

class _CrearView extends StatelessWidget {
  const _CrearView({
    required this.controlador,
    required this.longitud,
    required this.mensaje,
    required this.onContinuar,
  });

  final TextEditingController controlador;
  final int longitud;
  final String? mensaje;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    return _ColumnaGate(
      titulo: 'Crea tu código de $longitud dígitos',
      explicacion:
          'Es el código de la zona de adultos. La app no guarda el código: '
          'guarda su huella, que no sirve para leerlo.',
      hijos: [
        _campoPin(controlador, longitud: longitud, onEnviado: onContinuar),
        if (mensaje != null) _AvisoError(texto: mensaje!),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: controlador.text.length == longitud ? onContinuar : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _ConfirmarView extends StatelessWidget {
  const _ConfirmarView({
    required this.controlador,
    required this.longitud,
    required this.mensaje,
    required this.onConfirmar,
    required this.onVolver,
  });

  final TextEditingController controlador;
  final int longitud;
  final String? mensaje;
  final Future<void> Function() onConfirmar;
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return _ColumnaGate(
      titulo: 'Confirma tu código',
      explicacion: 'Escribe los mismos $longitud dígitos otra vez.',
      hijos: [
        _campoPin(controlador, longitud: longitud, onEnviado: () => onConfirmar()),
        if (mensaje != null) _AvisoError(texto: mensaje!),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed:
              controlador.text.length == longitud ? () => onConfirmar() : null,
          child: const Text('Confirmar'),
        ),
        TextButton(
          onPressed: onVolver,
          child: const Text('Volver a empezar'),
        ),
      ],
    );
  }
}

class _PedirView extends ConsumerWidget {
  const _PedirView({
    required this.estado,
    required this.controlador,
    required this.verificando,
    required this.onEntrar,
    required this.onBiometria,
    required this.onOlvide,
  });

  final GateEstado estado;
  final TextEditingController controlador;
  final bool verificando;
  final Future<void> Function() onEntrar;
  final Future<void> Function() onBiometria;
  final VoidCallback onOlvide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometriaActiva = ref.watch(biometriaHabilitadaProvider);
    // Bloqueo heredado de otra sesión: el mensaje se deduce del contador,
    // así nunca se ve un botón desactivado sin explicación.
    final aviso =
        estado.mensaje ??
        (estado.bloqueado
            ? 'Demasiados intentos. Espera ${estado.bloqueo.inSeconds} '
                  'segundos.'
            : null);

    return _ColumnaGate(
      titulo: 'Escribe tu código',
      explicacion: 'Zona de adultos: control parental, métricas y documentos.',
      hijos: [
        _campoPin(
          controlador,
          longitud: estado.longitud,
          onEnviado: () => onEntrar(),
        ),
        if (aviso != null) ...[
          const SizedBox(height: 8),
          _AvisoError(texto: aviso),
        ],
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: estado.bloqueado ||
                  verificando ||
                  controlador.text.length != estado.longitud
              ? null
              : () => onEntrar(),
          child: const Text('Entrar'),
        ),
        if (biometriaActiva) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: estado.bloqueado || verificando
                ? null
                : () => onBiometria(),
            child: const Text('Usar huella o rostro'),
          ),
        ],
        const SizedBox(height: 8),
        // Plan 11 §1.2: única salida para un PIN olvidado, con la ventana
        // de borrado de datos detrás.
        TextButton(
          onPressed: onOlvide,
          child: const Text('¿Olvidaste el código?'),
        ),
      ],
    );
  }
}

/// Aviso de error en rojo suave, con región viva para lector de pantalla.
class _AvisoError extends StatelessWidget {
  const _AvisoError({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          texto,
          style: const TextStyle(color: AppColors.onError),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
