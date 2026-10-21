import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/di.dart';
import 'filtro_web_gateway.dart';
import 'filtro_web_model.dart';

/// Claves de preferencias del filtro. Todas son locales.
class FiltroWebPrefs {
  static const activo = 'padre_filtro_web_activo';
  static const adultos = 'padre_filtro_web_adultos';
  static const apuestas = 'padre_filtro_web_apuestas';
  static const redes = 'padre_filtro_web_redes';
  static const juegos = 'padre_filtro_web_juegos';
  static const buscadores = 'padre_filtro_web_buscadores';
  static const personalizados = 'padre_filtro_web_custom';

  static FiltroWebConfig leer(SharedPreferences prefs) {
    final crudos = prefs.getString(personalizados);
    final dominios = <String>[];
    if (crudos != null) {
      try {
        final lista = jsonDecode(crudos);
        if (lista is List) {
          for (final item in lista) {
            if (item is String) {
              final normalizado = normalizarDominio(item);
              if (normalizado != null && !dominios.contains(normalizado)) {
                dominios.add(normalizado);
              }
            }
          }
        }
      } on FormatException {
        // Lista corrupta: se ignora y el adulto puede volver a agregar.
      }
    }
    return FiltroWebConfig(
      activo: prefs.getBool(activo) ?? false,
      bloquearAdultos: prefs.getBool(adultos) ?? true,
      bloquearApuestas: prefs.getBool(apuestas) ?? true,
      bloquearRedes: prefs.getBool(redes) ?? true,
      bloquearJuegos: prefs.getBool(juegos) ?? false,
      bloquearBuscadores: prefs.getBool(buscadores) ?? false,
      dominiosPersonalizados: List.unmodifiable(dominios),
    );
  }

  static Future<void> guardar(
    SharedPreferences prefs,
    FiltroWebConfig config,
  ) async {
    await prefs.setBool(activo, config.activo);
    await prefs.setBool(adultos, config.bloquearAdultos);
    await prefs.setBool(apuestas, config.bloquearApuestas);
    await prefs.setBool(redes, config.bloquearRedes);
    await prefs.setBool(juegos, config.bloquearJuegos);
    await prefs.setBool(buscadores, config.bloquearBuscadores);
    await prefs.setString(
      personalizados,
      jsonEncode(config.dominiosPersonalizados),
    );
  }
}

/// Resultado de agregar un sitio: sirve para que la pantalla muestre un
/// mensaje literal sin adivinar qué pasó.
typedef ResultadoDominio = ({ResultadoAgregar resultado, String? dominio});

/// Control del filtro. El estado `activo` es el estado deseado; el estado
/// real de la VPN se consulta aparte con [filtroWebEstadoProvider].
class FiltroWebController extends Notifier<FiltroWebConfig> {
  @override
  FiltroWebConfig build() =>
      FiltroWebPrefs.leer(ref.read(sharedPreferencesProvider));

  Future<void> _guardar(FiltroWebConfig next) async {
    state = next;
    await FiltroWebPrefs.guardar(
      ref.read(sharedPreferencesProvider),
      next,
    );
  }

  /// Enciende o apaga el filtro. Devuelve `false` si Android no dio el
  /// permiso de VPN o el servicio no pudo arrancar.
  Future<bool> setActivo(bool activo) async {
    if (activo == state.activo) return true;
    final gateway = ref.read(filtroWebGatewayProvider);
    final next = state.copyWith(activo: activo);

    if (activo) {
      // La lista debe estar en el servicio ANTES de arrancar. Así, si
      // Android vuelve a iniciar el servicio (por ejemplo, con la VPN
      // «siempre activa»), encuentra la copia nativa actualizada.
      await gateway.actualizar(next);
      final ok = await gateway.activar();
      if (!ok) {
        final apagado = state.copyWith(activo: false);
        await _guardar(apagado);
        // Dejar también la copia nativa en apagado: si Android inicia la
        // VPN por «siempre activa», no debe bloquear contra la voluntad
        // del adulto.
        await gateway.actualizar(apagado);
        return false;
      }
    } else {
      // Primero se apaga el filtro en la copia nativa y después se para el
      // servicio: así una VPN «siempre activa» no sigue bloqueando.
      await gateway.actualizar(next);
      await gateway.desactivar();
    }

    await _guardar(next);
    return true;
  }

  Future<void> setCategoria(CategoriaSitio categoria, bool valor) async {
    final next = state.conCategoria(categoria, valor);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
  }

  Future<ResultadoDominio> agregarDominio(String entrada) async {
    final dominio = normalizarDominio(entrada);
    if (dominio == null) {
      return (resultado: ResultadoAgregar.invalido, dominio: null);
    }
    if (state.dominiosPersonalizados.contains(dominio)) {
      return (resultado: ResultadoAgregar.duplicado, dominio: dominio);
    }
    if (state.dominiosPersonalizados.length >=
        FiltroWebConfig.maxPersonalizados) {
      return (resultado: ResultadoAgregar.lleno, dominio: dominio);
    }

    final lista = [...state.dominiosPersonalizados, dominio]..sort();
    final next = state.copyWith(dominiosPersonalizados: lista);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
    return (resultado: ResultadoAgregar.agregado, dominio: dominio);
  }

  Future<void> quitarDominio(String dominio) async {
    final lista = state.dominiosPersonalizados
        .where((item) => item != dominio)
        .toList();
    final next = state.copyWith(dominiosPersonalizados: lista);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
  }

  Future<void> limpiarRegistro() =>
      ref.read(filtroWebGatewayProvider).limpiarRegistro();
}

final filtroWebGatewayProvider = Provider<FiltroWebGateway>(
  (ref) => const PlatformFiltroWebGateway(),
);

final filtroWebProvider =
    NotifierProvider<FiltroWebController, FiltroWebConfig>(
  FiltroWebController.new,
);

/// Estado real de la VPN según Android. Se refresca al abrir la pantalla y
/// con el botón «Actualizar».
final filtroWebEstadoProvider =
    FutureProvider.autoDispose<FiltroWebEstado>((ref) {
  return ref.read(filtroWebGatewayProvider).estado();
});
