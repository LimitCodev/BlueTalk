import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import '../filtro_web/filtro_web_controller.dart';
import '../monitoreo/uso_telefono_controller.dart';
import 'permiso_model.dart';
import 'permisos_gateway.dart';

/// Acceso nativo a avisos y batería.
final permisosGatewayProvider = Provider<PermisosGateway>(
  (ref) => const PlatformPermisosGateway(),
);

/// Diagnóstico de todos los permisos, leído de Android de una vez.
///
/// Las cuatro consultas corren en paralelo y nunca lanzan: una que falle
/// deja su permiso como [EstadoPermiso.desconocido]. Ningún permiso de esta
/// lista es obligatorio (P0-4 de Play): el comunicador y el panel del
/// adulto funcionan sin concederlos; el asistente solo los explica.
final permisosProvider = FutureProvider<PermisosEstado>((ref) async {
  final avisos = ref.watch(permisosGatewayProvider);
  final uso = ref.watch(usoTelefonoGatewayProvider);
  final filtro = ref.watch(filtroWebGatewayProvider);
  final directa = ref.watch(edicionDirectaProvider);
  final filtroActivo = directa && ref.watch(filtroWebProvider).activo;

  // Disparadas todas antes de esperar: que no se serialicen.
  final avisosP = avisos.estadoAvisos();
  final bateriaP = avisos.estadoBateria();
  final usoP = uso.estadoPermiso();
  final vpnP = filtro.estado();

  // El canal de la VPN se dispara siempre, pero **solo se espera** si el
  // filtro está encendido: sin filtro no hay nada que pedir, y esperarlo
  // en pruebas (donde ese canal no contesta) dejaría el diagnóstico entero
  // girando sin terminar. El gateway nunca lanza, así que no queda ningún
  // futuro sin consumir.
  EstadoPermiso? estadoVpn;
  if (filtroActivo) {
    final vpn = await vpnP;
    estadoVpn = vpn.comprobado
        ? estadoDesdeBool(vpn.consentimiento)
        : EstadoPermiso.desconocido;
  }

  final lista = <PermisoPadre>[
    PermisoPadre(
      id: PermisoId.avisos,
      titulo: 'Avisos del teléfono',
      paraQueSirve:
          'Para que el horario avise cuando toque pasar de actividad.',
      queNoLee:
          'BlueTalk no lee los avisos de otras apps. Solo avisa de las '
          'actividades del horario, a la hora que tú pusiste.',
      estado: await avisosP,
      requerido: false,
    ),
    PermisoPadre(
      id: PermisoId.uso,
      titulo: 'Acceso al uso de las apps',
      paraQueSirve: 'Para el tiempo por app en el Resumen y en los informes '
          'semanal y mensual. Se guarda solo en este teléfono.',
      queNoLee:
          'Solo se leen el nombre de la app y el tiempo en primer plano. '
          'No se leen mensajes, fotos, historiales ni nada escrito.',
      // Tri-estado: si el canal no contesta, «no se pudo comprobar» no
      // bloquea. Bloquear con un fallo de consulta dejaría al adulto sin
      // salida, porque «pedir» devuelve lo mismo que ya falló.
      estado: await usoP,
      requerido: false,
    ),
    PermisoPadre(
      id: PermisoId.bateria,
      titulo: 'Batería sin ahorro para BlueTalk',
      paraQueSirve:
          'Para que el filtro de páginas siga cortando con el teléfono '
          'en reposo.',
      queNoLee:
          'No se lee el nivel ni el consumo de batería, ni el de otras apps.',
      estado: await bateriaP,
      requerido: false,
    ),
    // La VPN solo se necesita si el filtro está encendido: mientras no lo
    // está, no hay nada que pedir y la lista no debe estorbar.
    if (filtroActivo)
      PermisoPadre(
        id: PermisoId.vpn,
        titulo: 'Permiso de VPN para el filtro',
        paraQueSirve:
            'Para cortar la conexión a los sitios que bloqueas.',
        queNoLee:
            'El tráfico no pasa por servidores de BlueTalk: la app solo '
            'comprueba nombres de dominio en el propio teléfono.',
        estado: estadoVpn ?? EstadoPermiso.desconocido,
        requerido: false,
      ),
  ];

  // Play (ruta A): sin VPN ni acceso al uso; la batería solo servía al filtro.
  return PermisosEstado([
    for (final p in lista)
      if (directa || p.id == PermisoId.avisos) p,
  ]);
});

/// Qué dice Android sobre un permiso, para la pantalla.
String estadoPermisoEnLlano(EstadoPermiso estado) => switch (estado) {
      EstadoPermiso.concedido => 'Concedido',
      EstadoPermiso.pendiente => 'Falta concederlo',
      EstadoPermiso.desconocido => 'No se pudo comprobar',
    };
