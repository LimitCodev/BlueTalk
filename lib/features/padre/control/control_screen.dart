import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/calm_mode.dart';
import '../../../core/widgets/section_header.dart';
import '../dashboard/barras.dart';
import '../filtro_web/filtro_web_controller.dart';
import '../filtro_web/filtro_web_screen.dart';
import '../gate/biometria.dart';
import '../legal/legal_controller.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../monitoreo/uso_telefono_screen.dart';
import '../padre_controller.dart';
import 'cambiar_codigo.dart';
import 'control_parental.dart';
import 'recuperacion_dialogo.dart';
import 'voz_diagnostico.dart';

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
    final filtro = ref.watch(filtroWebProvider);
    final filtroEstado = ref.watch(filtroWebEstadoProvider).value;
    final permisoUso = ref.watch(permisoUsoProvider).value;
    final vpnConcedida = filtroEstado?.consentimiento ?? false;
    final usoConcedido = permisoUso ?? false;

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
        const SectionHeader('Permisos del teléfono'),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Permiso de VPN para el filtro'),
          subtitle: Text(
            vpnConcedida
                ? 'Concedido. Android ya autorizó la VPN local.'
                : 'Pendiente: se pide al encender el filtro de páginas.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const FiltroWebScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.query_stats),
          title: const Text('Acceso al uso de las apps'),
          subtitle: Text(
            usoConcedido
                ? 'Concedido. Ya se puede ver el tiempo por app.'
                : 'Pendiente: necesario para el diagnóstico de uso.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const UsoTelefonoScreen()),
          ),
        ),
        const SectionHeader('Protección en internet'),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Filtro de páginas'),
          subtitle: Text(
            filtro.activo
                ? 'Activo: bloquea los sitios elegidos.'
                : 'Apagado: los sitios no se bloquean.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const FiltroWebScreen()),
          ),
        ),
        const SectionHeader('Diagnóstico de uso'),
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: const Text('Tiempo por app'),
          subtitle: Text(
            usoConcedido
                ? 'Revisa cuánto tiempo estuvo abierta cada app.'
                : 'Falta el permiso «Acceso al uso» de Android.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const UsoTelefonoScreen()),
          ),
        ),
        const SectionHeader('Pantalla y voz'),
        const CalmModeToggle(),
        ListTile(
          leading: const Icon(Icons.text_fields_outlined),
          title: const Text('Tamaño de texto y velocidad de voz'),
          subtitle: const Text('Se cambian en la pestaña Ajustes.'),
          trailing: const Icon(Icons.chevron_right),
          // Enlace real a Ajustes: la app no duplica esa lógica aquí.
          onTap: () => GoRouter.maybeOf(context)?.go('/home/ajustes'),
        ),
        ListTile(
          leading: const Icon(Icons.record_voice_over_outlined),
          title: const Text('Probar la voz'),
          subtitle: const Text('¿No se oye? Comprueba el sonido aquí.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const VozDiagnosticoScreen()),
          ),
        ),
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
