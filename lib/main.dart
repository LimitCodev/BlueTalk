import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'data/local/mock_repos.dart';
import 'features/onboarding/profile_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga ajustes, modo calma y perfil antes del primer frame (sin parpadeo).
  final prefs = await SharedPreferences.getInstance();
  final profile = await PrefsProfileRepo(prefs).currentProfile();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(profile),
      ],
      child: const BlueTalkApp(),
    ),
  );
}
