import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'proteccion_gateway.dart';

/// Acceso nativo a la protección contra desinstalación.
final proteccionGatewayProvider = Provider<ProteccionGateway>(
  (ref) => const PlatformProteccionGateway(),
);

/// Estado actual de la protección, leído de Android cada vez que se pide.
final proteccionProvider = FutureProvider<ProteccionEstado>(
  (ref) => ref.watch(proteccionGatewayProvider).estado(),
);
