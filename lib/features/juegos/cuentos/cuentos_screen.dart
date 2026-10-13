import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../cabecera_juego.dart';
import '../juegos_catalog.dart';
import 'cuentos_controller.dart';

/// Juego cuentos interactivos (plan 03 §3): lista, lector de páginas y
/// tarea "¡Completar cuento!".
class CuentosScreen extends ConsumerWidget {
  const CuentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider);

    return switch (estado) {
      AsyncData(:final value) => value.enLista
          ? const Column(
              children: [
                CabeceraJuego('Cuentos interactivos'),
                Expanded(child: _ListaCuentos()),
              ],
            )
          : Column(
              children: [
                _CabeceraCuentos(storyId: value.storyId!),
                Expanded(
                  child: switch (value.fase) {
                    CuentoFase.leyendo => const _LectorCuento(),
                    CuentoFase.completar => const _TareaCompletar(),
                    CuentoFase.completado => const _CuentoCompletado(),
                  },
                ),
              ],
            ),
      AsyncError() => const Center(
          child: Text('No se pudieron cargar los cuentos.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Cabecera del lector: "Volver" a la lista + título del cuento.
class _CabeceraCuentos extends ConsumerWidget {
  const _CabeceraCuentos({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    String titulo = storyId;
    for (final cuento in cuentos) {
      if (cuento.id == storyId) titulo = cuento.title;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(cuentosProvider.notifier).irALista(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de los 3 cuentos seed; los completados muestran una estrella.
class _ListaCuentos extends ConsumerWidget {
  const _ListaCuentos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentos = ref.watch(cuentosSeedProvider);
    final pictos = ref.watch(pictosProvider).value ?? const [];
    final completados =
        ref.watch(cuentosProvider).value?.completados ?? const {};

    return switch (cuentos) {
      AsyncData(:final value) => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final cuento = value[index];
            final completado = completados.contains(cuento.id);
            return Card(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    ref.read(cuentosProvider.notifier).abrirCuento(cuento.id),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _PictoChico(asset: pictoAssetDe(pictos, cuento.coverPictoId)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cuento.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (completado)
                          const Icon(
                            Icons.star,
                            color: AppColors.primaryStrong,
                            semanticLabel: 'Cuento completado',
                          ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      AsyncError() => const Center(
          child: Text('No se pudieron cargar los cuentos.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Lector de páginas: texto literal + pictos clave de la página.
class _LectorCuento extends ConsumerWidget {
  const _LectorCuento();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider).requireValue;
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    final pictos = ref.watch(pictosProvider).value ?? const [];

    Story? cuento;
    for (final c in cuentos) {
      if (c.id == estado.storyId) cuento = c;
    }
    if (cuento == null) return const SizedBox.shrink();

    final texto = cuento.pages[estado.pagina];
    final claves = pictosClaveDePagina(
      texto,
      pictos,
      coverPictoId: cuento.coverPictoId,
    );
    final ultima = estado.pagina + 1 == cuento.pages.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final picto in claves) _PictoGrande(picto: picto),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            'Página ${estado.pagina + 1} de ${cuento.pages.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              if (estado.pagina > 0)
                OutlinedButton.icon(
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
                  onPressed: () =>
                      ref.read(cuentosProvider.notifier).anterior(),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Anterior'),
                ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 48),
                ),
                onPressed: () =>
                    ref.read(cuentosProvider.notifier).siguiente(),
                icon: Icon(ultima ? Icons.check : Icons.chevron_right),
                label: Text(ultima ? '¡Completar cuento!' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarea "¡Completar cuento!": una página con un hueco y 3 opciones
/// táctiles. Tocar la correcta completa el cuento.
class _TareaCompletar extends ConsumerWidget {
  const _TareaCompletar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider).requireValue;
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    final pictos = ref.watch(pictosProvider).value ?? const [];

    Story? cuento;
    for (final c in cuentos) {
      if (c.id == estado.storyId) cuento = c;
    }
    if (cuento == null || estado.opciones.isEmpty) {
      return const Center(child: Text('Este cuento no tiene imagen.'));
    }

    final opciones = [
      for (final id in estado.opciones)
        for (final picto in pictos)
          if (picto.id == id) picto,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '¡Completar cuento!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            cuento.pages.last,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          // Hueco: el sitio de la imagen que falta.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.primaryStrong, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 44,
                color: AppColors.primaryStrong,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca la imagen que falta.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final opcion in opciones)
                _OpcionTarea(
                  picto: opcion,
                  incorrecta: estado.opcionIncorrecta == opcion.id,
                  onTap: () => ref
                      .read(cuentosProvider.notifier)
                      .tocarOpcion(opcion.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "¡Cuento completado! 🎉" con la salida al lector o a la lista.
class _CuentoCompletado extends ConsumerWidget {
  const _CuentoCompletado();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Cuento completado! 🎉',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => ref.read(cuentosProvider.notifier).reiniciar(),
              child: const Text('Leer el cuento otra vez'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => ref.read(cuentosProvider.notifier).irALista(),
              child: const Text('Volver a los cuentos'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción táctil de la tarea; la incorrecta tocada queda con borde de
/// error hasta acertar (feedback por estado, sin parpadeos).
class _OpcionTarea extends StatelessWidget {
  const _OpcionTarea({
    required this.picto,
    required this.incorrecta,
    required this.onTap,
  });

  final Pictogram picto;
  final bool incorrecta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: picto.label,
      child: InkWell(
        key: ValueKey('opcion_${picto.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: incorrecta ? AppColors.error : AppColors.surface,
            border: Border.all(
              color: incorrecta ? AppColors.onError : AppColors.primaryStrong,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                picto.asset,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
                // Sin spinner animado: solo un espacio neutro al cargar.
                placeholderBuilder: (context) => const SizedBox(
                  width: 52,
                  height: 52,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                picto.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picto pequeño de portada en la lista.
class _PictoChico extends StatelessWidget {
  const _PictoChico({required this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: asset == null
          ? const Icon(Icons.menu_book, color: AppColors.primaryStrong)
          : SvgPicture.asset(
              asset!,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => const SizedBox(
                width: 44,
                height: 44,
              ),
            ),
    );
  }
}

/// Picto grande de la página.
class _PictoGrande extends StatelessWidget {
  const _PictoGrande({required this.picto});

  final Pictogram picto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: picto.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            picto.asset,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => const SizedBox(
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 4),
          Text(picto.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Asset SVG del picto por id; null si no existe.
String? pictoAssetDe(List<Pictogram> pictos, String? id) {
  if (id == null) return null;
  for (final picto in pictos) {
    if (picto.id == id) return picto.asset;
  }
  return null;
}
