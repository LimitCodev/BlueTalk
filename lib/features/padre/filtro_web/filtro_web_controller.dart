import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluetalk/core/almacen/almacen_local.dart';

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
  static const safeSearch = 'padre_filtro_web_safesearch';
  static const palabras = 'padre_filtro_web_palabras';
  static const permitidos = 'padre_filtro_web_permitidos';

  static FiltroWebConfig leer(AlmacenLocal prefs) {
    final crudos = prefs.texto(personalizados);
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
      activo: prefs.booleano(activo) ?? false,
      bloquearAdultos: prefs.booleano(adultos) ?? true,
      bloquearApuestas: prefs.booleano(apuestas) ?? true,
      bloquearRedes: prefs.booleano(redes) ?? true,
      bloquearJuegos: prefs.booleano(juegos) ?? false,
      bloquearBuscadores: prefs.booleano(buscadores) ?? false,
      dominiosPersonalizados: List.unmodifiable(dominios),
      // Encendido por defecto: es lo protector, y el adulto puede apagarlo.
      forzarSafeSearch: prefs.booleano(safeSearch) ?? true,
      palabrasProhibidas: _listaDeTexto(prefs, palabras, normalizarPalabra),
      dominiosPermitidos: _listaDeTexto(prefs, permitidos, normalizarDominio),
    );
  }

  /// Lee una lista de texto guardada como JSON, normalizando cada entrada.
  static List<String> _listaDeTexto(
    AlmacenLocal prefs,
    String clave,
    String? Function(String) normalizar,
  ) {
    final crudos = prefs.texto(clave);
    if (crudos == null) return const [];
    final salida = <String>[];
    try {
      final lista = jsonDecode(crudos);
      if (lista is List) {
        for (final item in lista) {
          if (item is String) {
            final normalizado = normalizar(item);
            if (normalizado != null && !salida.contains(normalizado)) {
              salida.add(normalizado);
            }
          }
        }
      }
    } on FormatException {
      // Lista corrupta: se ignora y el adulto puede volver a agregar.
    }
    return List.unmodifiable(salida);
  }

  static Future<void> guardar(
    AlmacenLocal prefs,
    FiltroWebConfig config,
  ) async {
    await prefs.guardarBooleano(activo, config.activo);
    await prefs.guardarBooleano(adultos, config.bloquearAdultos);
    await prefs.guardarBooleano(apuestas, config.bloquearApuestas);
    await prefs.guardarBooleano(redes, config.bloquearRedes);
    await prefs.guardarBooleano(juegos, config.bloquearJuegos);
    await prefs.guardarBooleano(buscadores, config.bloquearBuscadores);
    await prefs.guardarTexto(
      personalizados,
      jsonEncode(config.dominiosPersonalizados),
    );
    await prefs.guardarBooleano(safeSearch, config.forzarSafeSearch);
    await prefs.guardarTexto(palabras, jsonEncode(config.palabrasProhibidas));
    await prefs.guardarTexto(permitidos, jsonEncode(config.dominiosPermitidos));
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
      FiltroWebPrefs.leer(ref.read(almacenLocalProvider));

  Future<void> _guardar(FiltroWebConfig next) async {
    state = next;
    await FiltroWebPrefs.guardar(
      ref.read(almacenLocalProvider),
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

  Future<void> setSafeSearch(bool valor) async {
    if (valor == state.forzarSafeSearch) return;
    final next = state.copyWith(forzarSafeSearch: valor);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
  }

  /// Agrega una palabra a la lista de bloqueadas. Igual que con los
  /// dominios, el resultado dice literalmente qué pasó para la pantalla.
  Future<ResultadoDominio> agregarPalabra(String entrada) async {
    final palabra = normalizarPalabra(entrada);
    if (palabra == null) {
      return (resultado: ResultadoAgregar.invalido, dominio: null);
    }
    if (state.palabrasProhibidas.contains(palabra)) {
      return (resultado: ResultadoAgregar.duplicado, dominio: palabra);
    }
    if (state.palabrasProhibidas.length >= FiltroWebConfig.maxPalabras) {
      return (resultado: ResultadoAgregar.lleno, dominio: palabra);
    }
    final lista = [...state.palabrasProhibidas, palabra]..sort();
    final next = state.copyWith(palabrasProhibidas: lista);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
    return (resultado: ResultadoAgregar.agregado, dominio: palabra);
  }

  Future<void> quitarPalabra(String palabra) async {
    final lista = state.palabrasProhibidas
        .where((item) => item != palabra)
        .toList();
    final next = state.copyWith(palabrasProhibidas: lista);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
  }

  /// Agrega un sitio que sí puede abrirse aunque se parezca a una palabra.
  Future<ResultadoDominio> agregarPermitido(String entrada) async {
    final dominio = normalizarDominio(entrada);
    if (dominio == null) {
      return (resultado: ResultadoAgregar.invalido, dominio: null);
    }
    if (state.dominiosPermitidos.contains(dominio)) {
      return (resultado: ResultadoAgregar.duplicado, dominio: dominio);
    }
    if (state.dominiosPermitidos.length >= FiltroWebConfig.maxPermitidos) {
      return (resultado: ResultadoAgregar.lleno, dominio: dominio);
    }
    final lista = [...state.dominiosPermitidos, dominio]..sort();
    final next = state.copyWith(dominiosPermitidos: lista);
    await _guardar(next);
    if (next.activo) {
      await ref.read(filtroWebGatewayProvider).actualizar(next);
    }
    return (resultado: ResultadoAgregar.agregado, dominio: dominio);
  }

  Future<void> quitarPermitido(String dominio) async {
    final lista = state.dominiosPermitidos
        .where((item) => item != dominio)
        .toList();
    final next = state.copyWith(dominiosPermitidos: lista);
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
