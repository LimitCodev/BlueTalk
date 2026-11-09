/// Los permisos que el control parental necesita en el teléfono.
///
/// Identificadores fijos: la pantalla y el controlador los usan para saber
/// qué petición toca en Android sin que el modelo cargue acciones.
enum PermisoId {
  /// Avisos del horario (`POST_NOTIFICATIONS`).
  avisos,

  /// Exclusión de optimización de batería, para que la VPN siga viva.
  bateria,

  /// «Acceso al uso» (`PACKAGE_USAGE_STATS`), para el tiempo por app.
  uso,

  /// Consentimiento de VPN del filtro de páginas (`VpnService`).
  vpn,
}

/// Cómo está un permiso según Android.
enum EstadoPermiso {
  /// El adulto ya lo concedió, o no hace falta todavía.
  concedido,

  /// Falta, y la app puede pedirlo ahora mismo.
  pendiente,

  /// No se pudo comprobar: sin canal nativo (tests, escritorio) o con una
  /// respuesta defectuosa del sistema.
  desconocido,
}

/// Traduce el `true`/`false` de un canal nativo. Cualquier otra respuesta
/// (sin canal, nula, de otro tipo) es [EstadoPermiso.desconocido].
EstadoPermiso estadoDesdeBool(Object? valor) => switch (valor) {
      true => EstadoPermiso.concedido,
      false => EstadoPermiso.pendiente,
      _ => EstadoPermiso.desconocido,
    };

/// Un permiso explicado para el asistente del adulto.
class PermisoPadre {
  const PermisoPadre({
    required this.id,
    required this.titulo,
    required this.paraQueSirve,
    required this.queNoLee,
    required this.estado,
    required this.requerido,
  });

  final PermisoId id;

  /// Nombre corto, con el que Android lo llama también.
  final String titulo;

  /// Qué se consigue con él, en lenguaje llano.
  final String paraQueSirve;

  /// Qué **no** lee esta app por tenerlo. Siempre en positivo.
  final String queNoLee;

  final EstadoPermiso estado;

  /// `true` = sin él la app no cumple su función. Hoy ninguno se marca así
  /// (P0-4 de Play): todos son opcionales y el panel se abre igual.
  final bool requerido;

  PermisoPadre copiarCon(EstadoPermiso nuevo) => PermisoPadre(
        id: id,
        titulo: titulo,
        paraQueSirve: paraQueSirve,
        queNoLee: queNoLee,
        estado: nuevo,
        requerido: requerido,
      );
}

/// Lista de permisos con su diagnóstico.
class PermisosEstado {
  const PermisosEstado(this.permisos);

  final List<PermisoPadre> permisos;

  static const completo = PermisosEstado([]);

  /// ¿Falta algún permiso marcado como necesario y que Android confirmó
  /// que no está concedido? Hoy la lista de producción no marca ninguno
  /// (P0-4 de Play), así que siempre es `false`; se conserva para permisos
  /// futuros. Los `desconocido` tampoco cuentan: impedir el modo padre
  /// porque una comprobación falló dejaría al adulto sin salida.
  bool get faltanRequeridos => permisos.any(
        (p) => p.requerido && p.estado == EstadoPermiso.pendiente,
      );

  List<PermisoPadre> get pendientes =>
      permisos.where((p) => p.estado == EstadoPermiso.pendiente).toList();

  PermisoPadre? de(PermisoId id) {
    for (final p in permisos) {
      if (p.id == id) return p;
    }
    return null;
  }
}
