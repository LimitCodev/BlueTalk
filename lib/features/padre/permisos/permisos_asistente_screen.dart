import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_header.dart';
import '../filtro_web/filtro_web_controller.dart';
import '../monitoreo/uso_telefono_controller.dart';
import '../proteccion/proteccion_controller.dart';
import 'permiso_model.dart';
import 'permisos_controller.dart';

/// Asistente de permisos del adulto (encargo §3.2).
///
/// Explica cada permiso en lenguaje llano, con lo que **no** lee la app,
/// comprueba su estado real en Android y no deja avanzar mientras falte
/// alguno de los que son obligatorios.
class PermisosAsistenteScreen extends ConsumerStatefulWidget {
  const PermisosAsistenteScreen({super.key, this.comoPaso = false});

  /// `true` cuando se muestra como paso obligatorio antes del panel, en vez
  /// de abrirse empujada desde el Control.
  final bool comoPaso;

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
    // En modo paso el Scaffold y la cabecera ya los pone PadreScreen, para
    // no meter una pantalla dentro de otra con dos barras.
    if (widget.comoPaso) return _cuerpo();

    return Scaffold(
      appBar: AppBar(title: const Text('Permisos del teléfono')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    final tema = Theme.of(context);
    final estado = ref.watch(permisosProvider).value;

    if (estado == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final faltan = estado.faltanRequeridos;
    final nombres = estado.pendientes
        .where((p) => p.requerido)
        .map((p) => p.titulo)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'BlueTalk funciona casi entero sin esto. Estos permisos son '
            'para el horario, el tiempo por pantalla y el filtro de '
            'páginas. Cada uno dice qué lee y qué no.',
          ),
        ),
        // El bloqueo: mientras esto se muestre, PadreScreen no enseña el
        // panel. Solo se bloquea con un «pendiente» que Android confirmó,
        // nunca con un «no se pudo comprobar».
        if (faltan)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tema.colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Todavía no se puede avanzar. Falta conceder: $nombres.',
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onError,
              ),
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
      EstadoPermiso.pendiente => Icons.error_outline,
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
                      color: tema.colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Text(
                '${estadoPermisoEnLlano(permiso.estado)}'
                '${permiso.requerido ? ' · necesario' : ' · opcional'}',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: pendiente
                      ? tema.colorScheme.onError
                      : tema.textTheme.bodySmall?.color,
                ),
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
