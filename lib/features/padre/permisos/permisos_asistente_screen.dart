import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../filtro_web/filtro_web_controller.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../proteccion/proteccion_controller.dart';
import 'permiso_model.dart';
import 'permisos_controller.dart';

/// Asistente de permisos del adulto (P0-4 de Play).
///
/// Explica cada permiso en lenguaje llano y con lo que **no** lee la app.
/// Ninguno es obligatorio: el comunicador y el panel funcionan sin ellos,
/// y el botón «Continuar sin estos permisos» siempre está disponible.
class PermisosAsistenteScreen extends ConsumerStatefulWidget {
  const PermisosAsistenteScreen({super.key});

  @override
  ConsumerState<PermisosAsistenteScreen> createState() =>
      _PermisosAsistenteScreenState();
}

class _PermisosAsistenteScreenState
    extends ConsumerState<PermisosAsistenteScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Volvemos de una pantalla de Android: algo puede haberse concedido.
    if (state == AppLifecycleState.resumed) ref.invalidate(permisosProvider);
  }

  /// Petición concreta para cada permiso.
  Future<void> _pedir(PermisoId id) async {
    final gateway = ref.read(permisosGatewayProvider);
    switch (id) {
      case PermisoId.avisos:
        await gateway.pedirAvisos();
      case PermisoId.bateria:
        await gateway.pedirBateria();
      case PermisoId.uso:
        await ref.read(usoTelefonoGatewayProvider).abrirAjustes();
      case PermisoId.vpn:
        await ref.read(filtroWebGatewayProvider).abrirAjustesVpn();
      case PermisoId.administrador:
        await ref.read(proteccionGatewayProvider).pedirActivacion();
    }
    ref.invalidate(permisosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(permisosProvider).value;
    final hayPendientes = estado?.pendientes.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Permisos del teléfono')),
      body: _cuerpo(),
      // La salida no depende de conceder nada: siempre está a la vista.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
            hayPendientes
                ? 'Continuar sin estos permisos'
                : 'Volver al panel',
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    final tema = Theme.of(context);
    final estado = ref.watch(permisosProvider).value;

    if (estado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'BlueTalk funciona sin conceder ninguno de estos permisos. '
            'Sirven para el horario, el tiempo por pantalla y el filtro de '
            'páginas. Cada uno dice qué lee y qué no.',
          ),
        ),
        // P0-4 de Play: ningún permiso es obligatorio. La tarjeta lo dice
        // sin rojo ni lenguaje de bloqueo.
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tema.colorScheme.surface,
            border: Border.all(color: tema.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Ninguno de estos permisos es obligatorio. El comunicador y el '
            'panel del adulto funcionan sin concederlos; actívalos solo si '
            'quieres avisos, informes de uso o el filtro de páginas.',
            style: tema.textTheme.bodyMedium,
          ),
        ),
        const SectionHeader('Permisos'),
        for (final permiso in estado.permisos) _fila(permiso),
        if (estado.permisos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay nada pendiente.'),
          ),
      ],
    );
  }

  Widget _fila(PermisoPadre permiso) {
    final tema = Theme.of(context);
    final pendiente = permiso.estado == EstadoPermiso.pendiente;
    final icono = switch (permiso.estado) {
      EstadoPermiso.concedido => Icons.check_circle_outline,
      EstadoPermiso.pendiente => Icons.info_outline,
      EstadoPermiso.desconocido => Icons.help_outline,
    };

    return ListTile(
      leading: Icon(icono),
      title: Text(permiso.titulo),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(permiso.paraQueSirve),
            const SizedBox(height: 4),
            Text(
              'No lee: ${permiso.queNoLee}',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pendiente
                  ? BoxDecoration(
                      border: Border.all(
                        color: tema.colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Text(
                '${estadoPermisoEnLlano(permiso.estado)}'
                '${permiso.requerido ? ' · necesario' : ' · opcional'}',
                style: tema.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      trailing: pendiente ? const Icon(Icons.chevron_right) : null,
      onTap: pendiente ? () => _pedir(permiso.id) : null,
    );
  }
}
