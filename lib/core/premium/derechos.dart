import 'plan.dart';

/// De dónde sale el plan de la persona adulta.
///
/// Hoy: [DerechosFijos] (gratis en release). Al conectar Google Play
/// Billing se añade una implementación que lee la compra verificada por
/// Play; nada más cambia (ver `docs/infra/aws-freemium.md` §Play).
abstract interface class FuenteDerechos {
  Future<Plan> plan();
}

/// Plan fijo, sin red ni compras.
///
/// El plan **no** se guarda en el almacén local: un valor editable en el
/// teléfono sería un premium gratis para quien lo toque. Para probar la
/// interfaz premium en desarrollo:
/// `flutter run --dart-define=BLUETALK_PLAN=premium`.
class DerechosFijos implements FuenteDerechos {
  const DerechosFijos([this._plan = _planDeCompilacion]);

  static const _planDeCompilacion =
      String.fromEnvironment('BLUETALK_PLAN') == 'premium'
          ? Plan.premium
          : Plan.gratis;

  final Plan _plan;

  @override
  Future<Plan> plan() async => _plan;
}
