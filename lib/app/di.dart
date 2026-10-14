import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/contracts/repos.dart';
import '../data/local/mock_repos.dart';
import '../data/local/seed_store.dart';

/// Instancia de preferencias de la app.
///
/// Se sobreescribe en `main()` tras cargarla (para no bloquear el arranque)
/// y en tests con `SharedPreferences.setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Se sobreescribe en main()'),
);

/// Flag para enchufar Supabase (plan 01 §6): `false` = MVP 100% local.
/// El backend se activa detrás de este flag sin tocar las pantallas.
final useSupabaseProvider = Provider<bool>((ref) => false);

/// Lector de seeds JSON (`assets/seed/`).
final seedStoreProvider = Provider<SeedStore>(
  (ref) => SeedStore(rootBundle.loadString),
);

// --- Repositorios: implementación local; Supabase llega tras el flag ---

final profileRepoProvider = Provider<ProfileRepo>(
  (ref) => PrefsProfileRepo(ref.watch(sharedPreferencesProvider)),
);

final pictogramRepoProvider = Provider<PictogramRepo>(
  (ref) => SeedPictogramRepo(ref.watch(seedStoreProvider)),
);

final storyRepoProvider = Provider<StoryRepo>(
  (ref) => SeedStoryRepo(ref.watch(seedStoreProvider)),
);

final gameProgressRepoProvider = Provider<GameProgressRepo>(
  (ref) => PrefsGameProgressRepo(ref.watch(sharedPreferencesProvider)),
);

final scheduleRepoProvider = Provider<ScheduleRepo>(
  (ref) => SeedScheduleRepo(
    ref.watch(seedStoreProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

final wellbeingRepoProvider = Provider<WellbeingRepo>(
  (ref) => PrefsWellbeingRepo(ref.watch(sharedPreferencesProvider)),
);

final usageRepoProvider = Provider<UsageRepo>(
  (ref) => PrefsUsageRepo(ref.watch(sharedPreferencesProvider)),
);

final settingsRepoProvider = Provider<SettingsRepo>(
  (ref) => PrefsSettingsRepo(ref.watch(sharedPreferencesProvider)),
);
