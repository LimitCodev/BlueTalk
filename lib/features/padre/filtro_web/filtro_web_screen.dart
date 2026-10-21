import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import 'filtro_web_controller.dart';
import 'filtro_web_gateway.dart';
import 'filtro_web_model.dart';

/// Pantalla del adulto para bloquear sitios en todo el teléfono.
///
/// Usa una VPN local que solo intercepta DNS: no desvía el resto del
/// tráfico. La explicación de límites está escrita en la propia pantalla
/// (plan 14) para que nadie crea que es un bloqueo total.
class FiltroWebScreen extends ConsumerStatefulWidget {
  const FiltroWebScreen({super.key});

  @override
  ConsumerState<FiltroWebScreen> createState() => _FiltroWebScreenState();
}

class _FiltroWebScreenState extends ConsumerState<FiltroWebScreen> {
  final _campo = TextEditingController();
  Timer? _refresco;

  @override
  void initState() {
    super.initState();
    // Mientras el adulto mira la pantalla, el estado real de la VPN se
    // refresca solo: si el niño la detuvo, se ve sin tener que reabrir.
    _refresco = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) ref.invalidate(filtroWebEstadoProvider);
    });
  }

  @override
  void dispose() {
    _refresco?.cancel();
    _campo.dispose();
    super.dispose();
  }

  Future<void> _cambiarActivo(bool valor) async {
    if (valor) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activar filtro de páginas'),
          content: const Text(
            'Android mostrará un aviso para crear una VPN local. '
            'BlueTalk la usa solo para bloquear los sitios que elijas. '
            'El historial de sitios no se envía a ningún servidor.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (continuar != true || !mounted) return;
    }

    final ok = await ref.read(filtroWebProvider.notifier).setActivo(valor);
    if (!mounted) return;
    if (!ok && valor) {
      _snack('No se activó. Revisa que Android permita la VPN a BlueTalk.');
    }
    ref.invalidate(filtroWebEstadoProvider);
  }

  Future<void> _reactivar() async {
    // `setActivo(true)` no hace nada si el estado deseado ya es «activo».
    // Se apaga primero para que el botón vuelva a arrancar el servicio.
    await ref.read(filtroWebProvider.notifier).setActivo(false);
    if (!mounted) return;
    await _cambiarActivo(true);
  }

  Future<void> _agregar() async {
    FocusScope.of(context).unfocus();
    final resultado =
        await ref.read(filtroWebProvider.notifier).agregarDominio(_campo.text);
    if (!mounted) return;

    switch (resultado.resultado) {
      case ResultadoAgregar.agregado:
        _campo.clear();
        _snack(
          'Se bloqueará ${resultado.dominio} y sus subdominios. '
          'No se puede bloquear solo una página dentro del sitio.',
        );
        ref.invalidate(filtroWebEstadoProvider);
      case ResultadoAgregar.duplicado:
        _snack('Ese sitio ya está en la lista.');
      case ResultadoAgregar.lleno:
        _snack(
          'La lista llegó al máximo de '
          '${FiltroWebConfig.maxPersonalizados} sitios.',
        );
      case ResultadoAgregar.invalido:
        _snack(
          'Escribe un sitio como ejemplo.com. '
          'No se puede bloquear una dirección IP ni una página suelta.',
        );
    }
  }

  Future<void> _quitar(String dominio) async {
    await ref.read(filtroWebProvider.notifier).quitarDominio(dominio);
    if (!mounted) return;
    _snack('Se quitó $dominio de la lista.');
    ref.invalidate(filtroWebEstadoProvider);
  }

  Future<void> _limpiarRegistro() async {
    await ref.read(filtroWebProvider.notifier).limpiarRegistro();
    if (!mounted) return;
    ref.invalidate(filtroWebEstadoProvider);
  }

  Future<void> _abrirAjustesVpn() async {
    final ok = await ref.read(filtroWebGatewayProvider).abrirAjustesVpn();
    if (!mounted) return;
    if (!ok) {
      _snack('No se pudo abrir los ajustes de VPN en este teléfono.');
    }
  }

  Future<void> _abrirAjustesDns() async {
    final ok = await ref.read(filtroWebGatewayProvider).abrirAjustesDns();
    if (!mounted) return;
    if (!ok) {
      _snack('Este teléfono no tiene la pantalla de DNS privado.');
    }
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _copiarDns() async {
    await Clipboard.setData(
      const ClipboardData(
        text: 'CleanBrowsing Family: 185.228.168.168 y 185.228.169.168\n'
            'Cloudflare Family: 1.1.1.3 y 1.0.0.3\n'
            'AdGuard Family: 94.140.14.15 y 94.140.15.16',
      ),
    );
    if (!mounted) return;
    _snack('Direcciones DNS copiadas.');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(filtroWebProvider);
    final estadoAsync = ref.watch(filtroWebEstadoProvider);
    final estado = estadoAsync.value;
    final detenido = config.activo &&
        !estadoAsync.isLoading &&
        !(estado?.activo ?? false);

    return Scaffold(
      appBar: AppBar(title: const Text('Filtro de páginas')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionHeader('Estado'),
          _TarjetaEstado(
            config: config,
            estado: estado,
            cargando: estadoAsync.isLoading,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 48),
              ),
              onPressed: detenido
                  ? _reactivar
                  : () => _cambiarActivo(!config.activo),
              icon: Icon(
                config.activo && !detenido
                    ? Icons.shield_outlined
                    : Icons.shield,
              ),
              label: Text(
                detenido
                    ? 'Reactivar filtro'
                    : config.activo
                        ? 'Apagar filtro'
                        : 'Activar filtro',
              ),
            ),
          ),
          if (estado?.dnsPrivado ?? false)
            _Aviso(
              texto: 'El DNS privado está activo y puede saltarse el filtro. '
                  'Desactívalo en los ajustes de red para que BlueTalk pueda '
                  'bloquear los sitios.',
              fondo: AppColors.warning,
              tinta: AppColors.onWarning,
              accion: TextButton(
                onPressed: _abrirAjustesDns,
                child: const Text('Abrir ajustes de DNS'),
              ),
            ),
          const SectionHeader('Qué prohibir'),
          for (final categoria in CategoriaSitio.values)
            SwitchListTile(
              title: Text(categoria.titulo),
              subtitle: Text(categoria.ayuda),
              value: config.estaActiva(categoria),
              onChanged: (valor) {
                ref
                    .read(filtroWebProvider.notifier)
                    .setCategoria(categoria, valor);
                ref.invalidate(filtroWebEstadoProvider);
              },
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Las listas son una ayuda inicial. Agrega los sitios concretos '
              'que quieras prohibir en el colegio.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SectionHeader('Prohibir un sitio'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _campo,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              onSubmitted: (_) => _agregar(),
              decoration: const InputDecoration(
                labelText: 'Pega la dirección del sitio',
                hintText: 'https://ejemplo.com',
                helperText: 'Se bloquea el sitio completo, no una página suelta.',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 48),
              ),
              onPressed: _agregar,
              icon: const Icon(Icons.block),
              label: const Text('Prohibir sitio'),
            ),
          ),
          if (config.dominiosPersonalizados.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Aún no agregaste sitios. Los grupos de arriba ya bloquean '
                'las listas recomendadas.',
              ),
            )
          else
            for (final dominio in config.dominiosPersonalizados)
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(dominio),
                subtitle: const Text('Bloqueado en este teléfono'),
                trailing: IconButton(
                  tooltip: 'Quitar $dominio',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _quitar(dominio),
                ),
              ),
          const SectionHeader('Intentos bloqueados'),
          if (estado == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Consultando el estado del filtro…'),
            )
          else if (estado.bloqueos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Aún no hay intentos bloqueados.'),
            )
          else ...[
            for (final bloqueo in estado.bloqueos.take(10))
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(bloqueo.dominio),
                subtitle: Text(_fechaHora(bloqueo.hora)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextButton.icon(
                onPressed: _limpiarRegistro,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Borrar registro'),
              ),
            ),
          ],
          const SectionHeader('Para el colegio y el Wi-Fi'),
          _GuiaColegio(
            onAbrirVpn: _abrirAjustesVpn,
            onCopiarDns: _copiarDns,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Text(
              'Este filtro es una ayuda, no un bloqueo total. Un niño con '
              'conocimientos podría desactivar la VPN desde los ajustes de '
              'Android. En el colegio, conviene combinarlo con el filtro del '
              'Wi-Fi y con un dispositivo administrado.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static String _fechaHora(DateTime fecha) {
    String dos(int valor) => valor.toString().padLeft(2, '0');
    return '${fecha.day}/${fecha.month} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}

class _TarjetaEstado extends StatelessWidget {
  const _TarjetaEstado({
    required this.config,
    required this.estado,
    required this.cargando,
  });

  final FiltroWebConfig config;
  final FiltroWebEstado? estado;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final activo = estado?.activo ?? false;
    final detenido = config.activo && !activo;
    final fondo = activo
        ? tema.colorScheme.primaryContainer
        : detenido
            ? AppColors.warning
            : tema.colorScheme.surfaceContainerHighest;
    final tinta = activo
        ? tema.colorScheme.onPrimaryContainer
        : detenido
            ? AppColors.onWarning
            : tema.colorScheme.onSurfaceVariant;

    final titulo = activo
        ? 'Filtro activo'
        : detenido
            ? 'El filtro no está activo'
            : 'Filtro apagado';
    final detalle = activo
        ? 'Android está usando la VPN local. '
            '${estado!.bloqueos.length} intento(s) bloqueado(s) guardados.'
        : detenido
            ? 'Si acabas de activarlo, espera unos segundos. '
                'Si sigue así, vuelve a activarlo.'
            : 'Los sitios de las listas no se están bloqueando.';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: fondo,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(activo ? Icons.shield : Icons.shield_outlined, color: tinta),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      color: tinta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(detalle, style: TextStyle(color: tinta)),
                  if (cargando) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(color: tinta),
                  ],
                  if (estado != null && !estado!.consentimiento) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Android pedirá permiso de VPN al activarlo.',
                      style: TextStyle(color: tinta, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.texto,
    required this.fondo,
    required this.tinta,
    this.accion,
  });

  final String texto;
  final Color fondo;
  final Color tinta;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texto, style: TextStyle(color: tinta)),
          ?accion,
        ],
      ),
    );
  }
}

class _GuiaColegio extends StatelessWidget {
  const _GuiaColegio({
    required this.onAbrirVpn,
    required this.onCopiarDns,
  });

  final VoidCallback onAbrirVpn;
  final VoidCallback onCopiarDns;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.school_outlined),
      title: const Text('Recomendaciones para el colegio'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.wifi),
          title: Text('Filtra también en el Wi-Fi'),
          subtitle: Text(
            'En el router del colegio, usa un DNS familiar. Cubre todos los '
            'dispositivos, no solo este teléfono.',
          ),
        ),
        SelectableText(
          'CleanBrowsing Family: 185.228.168.168 y 185.228.169.168\n'
          'Cloudflare Family: 1.1.1.3 y 1.0.0.3\n'
          'AdGuard Family: 94.140.14.15 y 94.140.15.16',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onCopiarDns,
            icon: const Icon(Icons.copy),
            label: const Text('Copiar direcciones'),
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.vpn_lock_outlined),
          title: Text('VPN siempre activa'),
          subtitle: Text(
            'Actívala en Ajustes de Android para que el filtro siga después '
            'de reiniciar el teléfono. Si puedes, activa también «Bloquear '
            'conexiones sin VPN».',
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: onAbrirVpn,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir ajustes de VPN'),
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.info_outline),
          title: Text('Qué no puede bloquear'),
          subtitle: Text(
            'Una página suelta dentro de un sitio, una dirección IP, una app '
            'con su propio DNS o un niño que apague la VPN desde Android. '
            'Para el colegio, un dispositivo administrado es más seguro.',
          ),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.public_off_outlined),
          title: Text('Chrome y el DNS seguro'),
          subtitle: Text(
            'Si el colegio usa Chrome, desactiva «Usar DNS seguro» en '
            'Ajustes › Privacidad y seguridad. Si sigue activo, Chrome puede '
            'saltarse este filtro.',
          ),
        ),
      ],
    );
  }
}
