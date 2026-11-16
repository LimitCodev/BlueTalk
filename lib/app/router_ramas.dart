import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ajustes/ajustes_screen.dart';
import '../features/comunicador/comunicador_screen.dart';
import '../features/juegos/juegos_screen.dart';
import '../features/padre/control/juegos_gate.dart';
import '../features/rutinas/rutinas_screen.dart';

/// Constructor de página del router (aplica el modo calma).
typedef ConstructorPagina =
    Page<Object?> Function(
      BuildContext context,
      GoRouterState state,
      Widget child,
    );

/// Ramas del shell: Comunicar · Aprender · Rutinas · Ajustes (orden fijo).
List<StatefulShellBranch> ramasShell(ConstructorPagina page) => [
  _rama('/home/comunicar', page, const ComunicadorScreen()),
  _rama('/home/aprender', page, const JuegosGate(juegos: JuegosScreen())),
  _rama('/home/rutinas', page, const RutinasScreen()),
  _rama('/home/ajustes', page, const AjustesScreen()),
];

StatefulShellBranch _rama(String ruta, ConstructorPagina page, Widget hijo) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: ruta,
          pageBuilder: (context, state) => page(context, state, hijo),
        ),
      ],
    );
