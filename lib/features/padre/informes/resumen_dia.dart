/// Lo que pasó en un día, resumido en el teléfono (informes semanal y
/// mensual). Solo cuentas y tiempos: nunca frases, textos ni contenido.
class ResumenDia {
  const ResumenDia({
    required this.dia,
    this.pictos = 0,
    this.categorias = const {},
    this.pictosUsados = const {},
    this.segundosJuego = 0,
    this.sesionesJuego = 0,
    this.cuentos = 0,
    this.dibujos = 0,
    this.actividadesHechas = const {},
    this.apps,
  });

  /// Clave `AAAA-MM-DD` (ver `dia.dart`).
  final String dia;
  final int pictos;

  /// Toques por categoría y por pictograma (`id` → toques).
  final Map<String, int> categorias;
  final Map<String, int> pictosUsados;
  final int segundosJuego;
  final int sesionesJuego;
  final int cuentos;
  final int dibujos;

  /// Ids de actividades del horario marcadas como hechas ese día.
  final Set<String> actividadesHechas;

  /// Uso de otras apps. `null` = no se pudo leer ese día (sin permiso o
  /// fuera de los ~10 días que Android conserva).
  final UsoAppsDia? apps;

  Map<String, Object?> toMap() => {
        'dia': dia,
        'p': pictos,
        'c': categorias,
        'u': pictosUsados,
        'sj': segundosJuego,
        'nj': sesionesJuego,
        'cu': cuentos,
        'di': dibujos,
        'ah': actividadesHechas.toList(),
        if (apps != null) 'ap': apps!.toMap(),
      };

  factory ResumenDia.fromMap(Map<String, dynamic> m) => ResumenDia(
        dia: m['dia'] as String,
        pictos: _entero(m['p']),
        categorias: _mapa(m['c']),
        pictosUsados: _mapa(m['u']),
        segundosJuego: _entero(m['sj']),
        sesionesJuego: _entero(m['nj']),
        cuentos: _entero(m['cu']),
        dibujos: _entero(m['di']),
        actividadesHechas: {...?(m['ah'] as List?)?.whereType<String>()},
        apps: m['ap'] is Map
            ? UsoAppsDia.fromMap(Map<String, dynamic>.from(m['ap'] as Map))
            : null,
      );
}

/// Uso de otras apps en un día: segundos en primer plano por paquete.
class UsoAppsDia {
  const UsoAppsDia({required this.totalSegundos, required this.apps});

  final int totalSegundos;

  /// Paquete → (nombre visible, segundos). Solo las que más se usaron.
  final Map<String, ({String nombre, int segundos})> apps;

  Map<String, Object?> toMap() => {
        't': totalSegundos,
        'a': {
          for (final e in apps.entries)
            e.key: {'n': e.value.nombre, 's': e.value.segundos},
        },
      };

  factory UsoAppsDia.fromMap(Map<String, dynamic> m) => UsoAppsDia(
        totalSegundos: _entero(m['t']),
        apps: {
          for (final e in (m['a'] as Map? ?? const {}).entries)
            if (e.value is Map)
              e.key as String: (
                nombre: (e.value as Map)['n'] as String? ?? '',
                segundos: _entero((e.value as Map)['s']),
              ),
        },
      );
}

int _entero(Object? v) => (v as num?)?.toInt() ?? 0;

Map<String, int> _mapa(Object? v) => {
      for (final e in (v as Map? ?? const {}).entries)
        e.key as String: _entero(e.value),
    };
