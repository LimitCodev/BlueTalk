import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instancia de preferencias de la app.
///
/// Se sobreescribe en `main()` tras cargarla (para no bloquear el arranque)
/// y en tests con `SharedPreferences.setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Se sobreescribe en main()'),
);
