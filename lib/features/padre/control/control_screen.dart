import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../dashboard/barras.dart';
import '../gate/biometria.dart';
import '../gate/gate_controller.dart';
import '../legal/legal_controller.dart';
import '../padre_controller.dart';
import '../permisos/permisos_asistente_screen.dart';
import 'cambiar_codigo.dart';
import 'control_dispositivo.dart';
import 'control_nino.dart';
import 'control_parental.dart';
import 'control_rutina_voz.dart';
import 'recuperacion_dialogo.dart';

/// Control parental (plan 05 §4): tiempo de juegos, secciones, pantalla y
/// voz (enlaces a Ajustes, sin duplicar lógica), desbloqueo y documentos.
class ControlScreen extends ConsumerWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limiteAsync = ref.watch(limiteJuegosProvider);
    final limite = limiteAsync.value ??
        const LimiteJuegos(
          minutosPorDia: 30,
          segundosUsados: 0,
          extensionMinutos: 0,
        );
    final cargando = limiteAsync.isLoading;
    final bloqueos = ref.watch(bloqueosProvider);
    final biometria = ref.watch(biometriaHabilitadaProvider);
    final aceptacion = ref.watch(legalProvider);
    // Dónde viven las huellas del código (lo decide `AlmacenPin`): se
    // enseña en pantalla para que un respaldo sin cifrar no pase
    // desapercibido (revisión de la fase 3a).
    final codigoCifrado = ref.watch(almacenPinProvider).cifrado;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SectionHeader('Tiempo de juegos'),
        SwitchListTile(
          title: const Text('Límite diario de juegos'),
          subtitle: const Text(
            'Al agotarse aparece un aviso suave, sin pantalla roja.',
          ),
          value: !limite.sinLimite,
          onChanged:
              cargando ? null : (valor) => ref
                  .read(limiteJuegosProvider.notifier)
                  .setActivo(valor),
        ),
        if (!limite.sinLimite) ...[
          ListTile(
            title: const Text('Minutos por día'),
            subtitle: Slider(
              value: limite.minutosPorDia.clamp(15, 120).toDouble(),
              min: 15,
              max: 120,
              divisions: 7,
              label: '${limite.minutosPorDia} min',
              onChanged: cargando
                  ? null
                  : (valor) => ref
                      .read(limiteJuegosProvider.notifier)
                      .setMinutosPorDia(valor.round()),
            ),
            trailing: Text('${limite.minutosPorDia} min'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarraDato(
              etiqueta: 'Tiempo de juegos hoy',
              valor: limite.minutosDisponibles == 0
                  ? 0
                  : limite.minutosUsados / limite.minutosDisponibles,
              detalle:
                  '${limite.minutosUsados} de ${limite.minutosDisponibles} min',
            ),
          ),
        ],
        const SectionHeader('Secciones'),
        SwitchListTile(
          title: const Text('Juegos'),
          subtitle: const Text(
            'Si lo apagas, no se podrá entrar a la pestaña Aprender.',
          ),
          value: !bloqueos.juegos,
          onChanged: (valor) =>
              ref.read(bloqueosProvider.notifier).setJuegos(!valor),
        ),
        SwitchListTile(
          title: const Text('Mi entorno'),
          subtitle: const Text(
            'Si lo apagas, no se podrá abrir la pantalla Mi entorno.',
          ),
          value: !bloqueos.entorno,
          onChanged: (valor) =>
              ref.read(bloqueosProvider.notifier).setEntorno(!valor),
        ),
        const SeccionNino(),
        const SectionHeader('Permisos del teléfono'),
        ListTile(
          leading: const Icon(Icons.rule_outlined),
          title: const Text('Revisar los permisos'),
          subtitle: const Text(
            'Qué pide y qué no lee. Puedes continuar sin concederlos.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const PermisosAsistenteScreen()),
          ),
        ),
        const SeccionesDispositivo(),
        const SeccionesRutinaYVoz(),
        const SectionHeader('Desbloqueo'),
        SwitchListTile(
          title: const Text('Huella o rostro'),
          subtitle: const Text(
            'Alternativa al código para entrar a la zona de adultos.',
          ),
          value: biometria,
          onChanged: (valor) =>
              ref.read(biometriaHabilitadaProvider.notifier).set(valor),
        ),
        ListTile(
          leading: const Icon(Icons.pin_outlined),
          title: const Text('Cambiar código'),
          subtitle: const Text('El código nuevo siempre tiene 6 dígitos.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const CambiarCodigoDialogo(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.vpn_key_outlined),
          title: const Text('Código de recuperación'),
          subtitle: const Text(
            'Para entrar si olvidas el código, sin borrar tus datos.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const RecuperacionDialogo(),
          ),
        ),
        ListTile(
          leading: Icon(
            codigoCifrado ? Icons.lock_outlined : Icons.lock_open_outlined,
          ),
          title: const Text('Dónde se guarda tu código'),
          subtitle: Text(
            codigoCifrado
                ? 'Cifrado por este teléfono. Solo se guarda la huella, '
                    'nunca el código.'
                : 'Este teléfono no pudo cifrarlo: la huella se guarda sin '
                    'cifrar, en los archivos de la app.',
          ),
        ),
        const SectionHeader('Documentos'),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Términos y privacidad'),
          subtitle: Text(
            aceptacion == null
                ? 'Sin aceptar'
                : 'Aceptados (versión ${aceptacion.version})',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => ref.read(padreProvider.notifier).irA(PadreVista.legal),
        ),
      ],
    );
  }
}
