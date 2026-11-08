import 'dart:convert';

import '../../../core/plataforma/canal_nativo.dart';

import 'filtro_web_model.dart';

/// Un intento de abrir un sitio bloqueado, guardado solo en este teléfono.
class BloqueoWeb {
  const BloqueoWeb({required this.dominio, required this.hora});

  final String dominio;
  final DateTime hora;

  factory BloqueoWeb.fromMap(Map<Object?, Object?> map) => BloqueoWeb(
        dominio: (map['dominio'] as String?) ?? '',
        hora: DateTime.fromMillisecondsSinceEpoch(
          (map['hora'] as num?)?.toInt() ?? 0,
        ),
      );
}

/// Estado real del filtro según Android (puede diferir del estado deseado
/// guardado en la app: el niño o el sistema pueden detener la VPN).
class FiltroWebEstado {
  const FiltroWebEstado({
    this.activo = false,
    this.consentimiento = false,
    this.dnsPrivado = false,
    this.bloqueos = const [],
    this.comprobado = true,
  });

  final bool activo;

  /// Android ya autorizó una VPN para esta app.
  final bool consentimiento;

  /// Hay DNS privado/HTTPS activo en la red: puede saltarse el filtro.
  final bool dnsPrivado;

  final List<BloqueoWeb> bloqueos;

  /// `false` cuando el canal nativo no contestó: `activo` y
  /// `consentimiento` dejan de significar algo, así que el asistente de
  /// permisos enseña «no se pudo comprobar» en vez de «falta concederlo».
  final bool comprobado;

  static const inactivo = FiltroWebEstado();

  /// Canal caído o sin contestar.
  static const sinComprobar = FiltroWebEstado(comprobado: false);

  factory FiltroWebEstado.fromMap(Map<Object?, Object?> map) {
    final crudos = map['bloqueos'];
    final bloqueos = <BloqueoWeb>[];
    if (crudos is List) {
      for (final item in crudos) {
        if (item is Map) bloqueos.add(BloqueoWeb.fromMap(item));
      }
    }
    return FiltroWebEstado(
      activo: map['activo'] as bool? ?? false,
      consentimiento: map['consentimiento'] as bool? ?? false,
      dnsPrivado: map['dnsPrivado'] as bool? ?? false,
      bloqueos: List.unmodifiable(bloqueos),
    );
  }
}

/// Puerta a la VPN local de Android. En tests se sustituye por un doble.
abstract interface class FiltroWebGateway {
  Future<FiltroWebEstado> estado();
  Future<bool> activar();
  Future<void> desactivar();
  Future<void> actualizar(FiltroWebConfig config);
  Future<void> limpiarRegistro();
  Future<bool> abrirAjustesVpn();
  Future<bool> abrirAjustesDns();
}

/// Implementación real con el canal nativo `bluetalk/filtro_web`.
///
/// Si el canal no existe (tests, escritorio), devuelve estados inofensivos
/// en lugar de romper la pantalla del adulto.
class PlatformFiltroWebGateway implements FiltroWebGateway {
  const PlatformFiltroWebGateway();

  static const _canal = CanalNativo('bluetalk/filtro_web');

  @override
  Future<FiltroWebEstado> estado() async {
    final mapa = await _canal.mapa('estado');
    return mapa == null
        ? FiltroWebEstado.sinComprobar
        : FiltroWebEstado.fromMap(mapa);
  }

  @override
  Future<bool> activar() => _canal.orden('activar');

  /// El servicio pudo haberse detenido solo; la UI muestra el estado real.
  @override
  Future<void> desactivar() => _canal.pedir<void>('desactivar');

  /// Sin canal la configuración queda guardada en el almacén local y se
  /// reintenta al activar o al volver a abrir la pantalla.
  @override
  Future<void> actualizar(FiltroWebConfig config) => _canal.pedir<void>(
        'actualizar',
        {'config': jsonEncode(config.paraServicioNativo)},
      );

  /// El registro es informativo; no se bloquea la pantalla por esto.
  @override
  Future<void> limpiarRegistro() => _canal.pedir<void>('limpiarRegistro');

  @override
  Future<bool> abrirAjustesVpn() => _canal.orden('abrirAjustesVpn');

  @override
  Future<bool> abrirAjustesDns() => _canal.orden('abrirAjustesDns');
}
