import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/di.dart';
import 'filtro_web/filtro_web_controller.dart' show filtroWebProvider;
import 'filtro_web/filtro_web_model.dart' show CategoriaSitio;

/// Perfil de edad (fase 3b, solicitud del dueño 2026-10-19).
///
/// La persona adulta elige la banda de edad del niño o niña. Con esa
/// elección:
///
/// - el comunicador **oculta categorías** que no son de esa edad (los
///   pictogramas guardados en una frase o en favoritos siguen existiendo:
///   solo se ocultan, no se borran nada);
/// - el filtro de páginas se ajusta a los grupos de esa edad (el adulto
///   puede cambiarlos después desde Protección en internet).
///
/// Es una ayuda, no una barrera: no decide qué es adecuado por el adulto,
/// solo aplica de una vez lo que él ya eligió.
enum PerfilEdad {
  ninguno(
    'Sin perfil',
    'Se ve todo. Los grupos del filtro de páginas quedan como los hayas '
        'dejado.',
    categorias: [],
    bloquearJuegos: null,
    bloquearBuscadores: null,
  ),
  pequenas(
    '3 a 5 años',
    'Categorías básicas del comunicador: emociones, comida, animales y '
        'familia. En el filtro se bloquean también los vídeos, los juegos '
        'y los buscadores.',
    categorias: ['emociones', 'comida', 'animales', 'familia'],
    bloquearJuegos: true,
    bloquearBuscadores: true,
  ),
  medianas(
    '6 a 8 años',
    'Se agregan acciones, objetos y clima al comunicador. En el filtro se '
        'bloquean adultos, apuestas y redes sociales.',
    categorias: [
      'emociones',
      'comida',
      'animales',
      'familia',
      'acciones',
      'objetos',
      'clima',
    ],
    bloquearJuegos: false,
    bloquearBuscadores: false,
  ),
  mayores(
    '9 a 12 años',
    'Todas las categorías del comunicador. En el filtro se bloquean '
        'adultos y apuestas; las redes sociales depende de ti.',
    categorias: [
      'emociones',
      'comida',
      'animales',
      'familia',
      'acciones',
      'objetos',
      'clima',
    ],
    bloquearJuegos: false,
    bloquearBuscadores: false,
  );

  const PerfilEdad(
    this.titulo,
    this.explicacion, {
    required this.categorias,
    required this.bloquearJuegos,
    required this.bloquearBuscadores,
  });

  final String titulo;

  /// Texto literal que se enseña al adulto en la pantalla de elección.
  final String explicacion;

  /// Ids de categorías visibles. Vacío = todas.
  final List<String> categorias;

  /// `null` = no tocar ese interruptor del filtro.
  final bool? bloquearJuegos;
  final bool? bloquearBuscadores;

  /// Categorías del comunicador que se ven con este perfil.
  bool seVe(String categoryId) => categorias.isEmpty || categorias.contains(categoryId);

  static const clavePref = 'padre_perfil_edad';

  static PerfilEdad desdePrefs(SharedPreferences prefs) =>
      desdeNombre(prefs.getString(clavePref));

  static PerfilEdad desdeNombre(String? nombre) => values.firstWhere(
        (perfil) => perfil.name == nombre,
        orElse: () => PerfilEdad.ninguno,
      );
}

class PerfilEdadController extends Notifier<PerfilEdad> {
  @override
  PerfilEdad build() => PerfilEdad.desdePrefs(ref.read(sharedPreferencesProvider));

  /// Elige el perfil. Además ajusta los grupos del filtro de páginas a los
  /// de esa edad; el adulto puede volver a cambiarlos después.
  Future<void> elegir(PerfilEdad perfil) async {
    state = perfil;
    await ref
        .read(sharedPreferencesProvider)
        .setString(PerfilEdad.clavePref, perfil.name);
    if (perfil.bloquearJuegos != null) {
      await ref
          .read(filtroWebProvider.notifier)
          .setCategoria(CategoriaSitio.juegos, perfil.bloquearJuegos!);
    }
    if (perfil.bloquearBuscadores != null) {
      await ref
          .read(filtroWebProvider.notifier)
          .setCategoria(CategoriaSitio.buscadores, perfil.bloquearBuscadores!);
    }
    // El SafeSearch siempre encendido con perfil: es lo protector.
    await ref.read(filtroWebProvider.notifier).setSafeSearch(true);
  }
}

final perfilEdadProvider = NotifierProvider<PerfilEdadController, PerfilEdad>(
  PerfilEdadController.new,
);
