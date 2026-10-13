import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de navegación del comunicador.
///
/// La pantalla gestiona su navegación de forma interna (inicio, categoría,
/// mis mensajes) en vez de usar rutas anidadas: el router raíz pertenece al
/// shell y así no hay acoplamiento entre agentes.
class ComunicadorViewState {
  const ComunicadorViewState({
    this.categoryId,
    this.query = '',
    this.showMessages = false,
  });

  /// Categoría abierta; null = en el inicio.
  final String? categoryId;

  /// Texto del buscador (vacío = sin búsqueda activa).
  final String query;

  /// true = vista "Mis mensajes" por delante del inicio.
  final bool showMessages;

  bool get onCategory => categoryId != null;
}

/// Controlador de la vista activa (persiste mientras viva el provider).
class ComunicadorController extends Notifier<ComunicadorViewState> {
  @override
  ComunicadorViewState build() => const ComunicadorViewState();

  void openCategory(String categoryId) => state = ComunicadorViewState(
        categoryId: categoryId,
        query: state.query,
      );

  void goHome() => state = ComunicadorViewState(query: state.query);

  void setQuery(String query) => state = ComunicadorViewState(
        categoryId: state.categoryId,
        query: query,
        showMessages: state.showMessages,
      );

  void showMessages() =>
      state = ComunicadorViewState(query: state.query, showMessages: true);
}

/// Vista activa del comunicador.
final comunicadorProvider =
    NotifierProvider<ComunicadorController, ComunicadorViewState>(
  ComunicadorController.new,
);
