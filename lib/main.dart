import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'data/local/mock_repos.dart';
import 'features/onboarding/profile_controller.dart';

/// RAM total del equipo en bytes vía `/proc/meminfo` (Android es Linux);
/// `null` si no se puede leer, y entonces no se aplica ningún tope.
int? _ramTotalBytes() {
  try {
    for (final linea in File('/proc/meminfo').readAsLinesSync()) {
      if (linea.startsWith('MemTotal:')) {
        final kb = int.tryParse(linea.split(RegExp(r'\s+'))[1]);
        if (kb != null) return kb * 1024;
      }
    }
  } catch (_) {
    // Sin /proc o sin permisos: se comporta como siempre.
  }
  return null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tope de imágenes en RAM con poca memoria (plan 00 §3.1, plan 11
  // §1.3.4): la rejilla de pictogramas no debe disparar el arranque.
  final ram = _ramTotalBytes();
  if (ram != null && ram <= 3 * 1024 * 1024 * 1024) {
    PaintingBinding.instance.imageCache
      ..maximumSize = 50
      ..maximumSizeBytes = 20 * 1024 * 1024;
  }

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
