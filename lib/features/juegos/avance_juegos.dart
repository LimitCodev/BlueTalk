import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_header.dart';
import 'artista/artista_dibujos.dart';
import 'juegos_catalog.dart';

/// Niveles del memoria: nivel 1 = 4 parejas y sube de 2 en 2
/// (plan 03 §2); 9 niveles = 20 parejas = 40 fichas, dentro de los
/// 42 pictos de la muestra.
const memoriaMaxNiveles = 9;

/// Resumen del avance del niño en los 3 juegos (plan 03 §5).
class AvanceJuegos {
  const AvanceJuegos({
    required this.memoriaNivel,
    required this.cuentosCompletados,
    required this.cuentosTotal,
    required this.dibujosGuardados,
  });

  /// Nivel más alto desbloqueado del memoria (1 = recién empezado).
  final int memoriaNivel;
  final int cuentosCompletados;
  final int cuentosTotal;

  /// Dibujos guardados en la galería local del artista.
  final int dibujosGuardados;

  int get memoriaSuperados => (memoriaNivel - 1).clamp(0, memoriaMaxNiveles);
}

/// Avance leído de `GameProgressRepo` (offline, con caché por pantalla).
final avanceJuegosProvider = FutureProvider<AvanceJuegos>((ref) async {
  final repo = ref.watch(gameProgressRepoProvider);
  final memoria = await repo.progress('memoria');
  final cuentos = await ref.watch(cuentosSeedProvider.future);
  final dibujos = ref.watch(galeriaDibujosProvider).length;

  var completados = 0;
  for (final cuento in cuentos) {
    // Cada cuento guarda su avance en su propio gameId (plan 03 §3).
    final progress = await repo.progress('cuentos:${cuento.id}');
    if (progress != null && progress.stars > 0) completados++;
  }

  return AvanceJuegos(
    memoriaNivel: memoria?.level ?? 1,
    cuentosCompletados: completados,
    cuentosTotal: cuentos.length,
    dibujosGuardados: dibujos,
  );
});

/// Sección "Avance en juegos" del home: barras hechas en Flutter
/// (sin librerías de gráficas, plan 03 §5).
class AvanceJuegosSection extends ConsumerWidget {
  const AvanceJuegosSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avance = ref.watch(avanceJuegosProvider);

    return switch (avance) {
      AsyncData(:final value) => _AvanceList(avance: value),
      AsyncError() => const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No se pudo cargar el avance.'),
        ),
      _ => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
    };
  }
}

class _AvanceList extends StatelessWidget {
  const _AvanceList({required this.avance});

  final AvanceJuegos avance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Avance en juegos'),
        _AvanceFila(
          titulo:
              'Memoria: ${avance.memoriaSuperados} de $memoriaMaxNiveles niveles superados',
          valor: avance.memoriaSuperados / memoriaMaxNiveles,
        ),
        _AvanceFila(
          titulo: 'Cuentos: ${avance.cuentosCompletados} de '
              '${avance.cuentosTotal} cuentos completados',
          valor: avance.cuentosTotal == 0
              ? 0
              : avance.cuentosCompletados / avance.cuentosTotal,
        ),
        _AvanceFila(
          titulo: 'Artista: ${avance.dibujosGuardados} '
              '${avance.dibujosGuardados == 1 ? 'dibujo guardado' : 'dibujos guardados'}',
          valor: (avance.dibujosGuardados / 5).clamp(0.0, 1.0),
        ),
      ],
    );
  }
}

/// Fila con etiqueta y barra de avance (targets ≥48dp).
class _AvanceFila extends StatelessWidget {
  const _AvanceFila({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          BarraAvance(valor: valor.clamp(0.0, 1.0), etiqueta: titulo),
        ],
      ),
    );
  }
}

/// Barra de avance hecha en Flutter: track + relleno, sin animación
/// (respetar Modo calma) y con semántica para lectores de pantalla.
class BarraAvance extends StatelessWidget {
  const BarraAvance({super.key, required this.valor, required this.etiqueta});

  /// Avance 0–1.
  final double valor;

  /// Texto leído por el lector de pantalla (p. ej. "2 de 3 cuentos").
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: etiqueta,
      child: Container(
        height: 12,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEF7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: valor,
          child: const ColoredBox(color: AppColors.primaryStrong),
        ),
      ),
    );
  }
}
