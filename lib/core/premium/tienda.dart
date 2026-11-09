/// Resultado de una compra o restauración en la tienda.
enum ResultadoCompra { comprado, cancelado, pendiente, noDisponible, error }

/// Contrato con la tienda de apps (Google Play Billing).
///
/// Se define ya para que la pantalla de compra y las pruebas no dependan
/// del paquete de pago. La implementación real necesita la dependencia
/// `in_app_purchase` y una cuenta de Play Console: decisión del dueño.
abstract interface class TiendaCompras {
  Future<bool> disponible();
  Future<ResultadoCompra> comprar(String idProducto);
  Future<ResultadoCompra> restaurar();
}

/// Tienda ausente: sin Play conectado, nada se puede comprar.
class TiendaNoDisponible implements TiendaCompras {
  const TiendaNoDisponible();

  @override
  Future<bool> disponible() async => false;

  @override
  Future<ResultadoCompra> comprar(String idProducto) async =>
      ResultadoCompra.noDisponible;

  @override
  Future<ResultadoCompra> restaurar() async => ResultadoCompra.noDisponible;
}
