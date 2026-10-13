import '../models/models.dart';

/// Contratos de datos (plan 01 §6).
///
/// Las features solo ven estas interfaces; la implementación local
/// (mock/Drift) o Supabase se decide detrás de `useSupabaseProvider`
/// sin tocar las pantallas.

abstract interface class ProfileRepo {
  Future<ChildProfile?> currentProfile();
  Future<void> saveProfile(ChildProfile profile);
}

abstract interface class PictogramRepo {
  /// Categorías ordenadas por [Category.order].
  Future<List<Category>> categories();
  Future<List<Pictogram>> pictogramsOf(String categoryId);
  Future<Pictogram?> pictogram(String id);
}

abstract interface class StoryRepo {
  Future<List<Story>> stories();
  Future<Story?> story(String id);
}

abstract interface class GameProgressRepo {
  Future<GameProgress?> progress(String gameId);
  Future<void> saveProgress(GameProgress progress);
}

abstract interface class ScheduleRepo {
  /// Entradas ordenadas por minuto del día.
  Future<List<ScheduleEntry>> schedule();
  Future<void> saveEntry(ScheduleEntry entry);
}

abstract interface class WellbeingRepo {
  Future<List<MoodEntry>> moods();
  Future<void> addMood(MoodEntry entry);
  Future<List<HabitEntry>> habits();
  Future<void> saveHabit(HabitEntry entry);
}

abstract interface class UsageRepo {
  Future<void> record(UsageEvent event);
  Future<List<UsageEvent>> events();
}

abstract interface class SettingsRepo {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}
