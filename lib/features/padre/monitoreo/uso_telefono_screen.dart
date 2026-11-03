import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import 'uso_telefono_controller.dart';
import 'uso_telefono_model.dart';

/// Diagnóstico de uso del teléfono para el adulto (plan 14).
///
/// Muestra cuánto tiempo estuvo cada app en primer plano. No muestra
/// mensajes, pantallas ni contenido: eso no se lee ni se guarda.
class UsoTelefonoScreen extends ConsumerStatefulWidget {
  const UsoTelefonoScreen({super.key});

  @override
  ConsumerState<UsoTelefonoScreen> createState() => _UsoTelefonoScreenState();
}

class _UsoTelefonoScreenState extends ConsumerState<UsoTelefonoScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los Ajustes de Android el permiso puede haber cambiado.
    if (state == AppLifecycleState.resumed) _refrescar();
  }

  void _refrescar() {
    ref.invalidate(permisoUsoProvider);
    ref.invalidate(resumenUsoProvider);
  }

  Future<void> _abrirAjustes() async {
    final ok = await ref.read(usoTelefonoGatewayProvider).abrirAjustes();
    if (!mounted) return;
    if (!ok) {
      _snack('No se pudo abrir los Ajustes de Android en este teléfono.');
      return;
    }
    _snack(
      'Busca BlueTalk en la lista y activa «Acceso al uso». '
      'Después vuelve aquí.',
    );
  }

  void _snack(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final permiso = ref.watch(permisoUsoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Uso del teléfono')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          switch (permiso) {
            AsyncData(:final value) when value => const _Contenido(),
            AsyncData(:final value) when !value => _Permiso(
                onAbrir: _abrirAjustes,
                onRefrescar: _refrescar,
              ),
            AsyncError() => _Permiso(
                onAbrir: _abrirAjustes,
                onRefrescar: _refrescar,
              ),
            _ => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
          },
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoUsoProvider);
    final resumen = ref.watch(resumenUsoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AvisoPrivacidad(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<PeriodoUso>(
            showSelectedIcon: false,
            segments: [
              for (final valor in PeriodoUso.values)
                ButtonSegment<PeriodoUso>(
                  value: valor,
                  label: Text(valor.titulo),
                ),
            ],
            selected: {periodo},
            onSelectionChanged: (seleccion) => ref
                .read(periodoUsoProvider.notifier)
                .set(seleccion.first),
          ),
        ),
        switch (resumen) {
          AsyncData(:final value) => _Resumen(resumen: value),
          AsyncError() => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('No se pudo leer el uso del teléfono.'),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(resumenUsoProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
      ],
    );
  }
}

class _AvisoPrivacidad extends StatelessWidget {
  const _AvisoPrivacidad();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Este diagnóstico se calcula en este teléfono y no se envía '
                'a ningún servidor. Solo muestra tiempos de uso por app; '
                'no lee mensajes, pantallas ni contenido.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.resumen});

  final ResumenUso resumen;

  @override
  Widget build(BuildContext context) {
    final total = resumen.totalSegundos;
    final maximo = resumen.apps.isEmpty ? 1 : resumen.apps.first.segundos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiempo total en apps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  formatearDuracion(total),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colores.primaryStrongText,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suma del tiempo en primer plano. No incluye la pantalla '
                  'apagada ni lo que se hizo dentro de cada app.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SectionHeader('Tiempo por app'),
        if (resumen.apps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No hay uso registrado en este periodo. Si acabas de activar '
              'el permiso, Android empieza a contar desde ahora.',
            ),
          )
        else
          Card(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Column(
              children: [
                for (var i = 0; i < resumen.apps.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _FilaUso(
                    app: resumen.apps[i],
                    maximo: maximo,
                  ),
                ],
              ],
            ),
          ),
        ExpansionTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Cómo se calcula'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            const Text(
              'Android guarda cuándo cada app pasa a primer plano y cuándo '
              'se oculta. BlueTalk suma esos ratos. Es una orientación para '
              'conversar con el niño o la niña, no un diagnóstico ni una '
              'prueba de lo que hizo.',
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const _DetalleTecnico(),
                ),
              ),
              icon: const Icon(Icons.list_alt),
              label: const Text('Apps incluidas y límites'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilaUso extends StatelessWidget {
  const _FilaUso({required this.app, required this.maximo});

  final UsoApp app;
  final int maximo;

  @override
  Widget build(BuildContext context) {
    final razon = maximo <= 0 ? 0.0 : app.segundos / maximo;
    final porcentaje = app.segundos <= 0 ? '0 min' : formatearDuracion(app.segundos);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _IconoApp(app: app),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        app.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      porcentaje,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: razon,
                    minHeight: 7,
                    backgroundColor: context.colores.borde,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconoApp extends StatelessWidget {
  const _IconoApp({required this.app});

  final UsoApp app;

  @override
  Widget build(BuildContext context) {
    final crudo = app.iconoBase64;
    Widget? imagen;
    if (crudo != null && crudo.isNotEmpty) {
      try {
        imagen = Image.memory(
          base64Decode(crudo),
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        );
      } on FormatException {
        imagen = null;
      }
    }
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.colores.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colores.borde),
      ),
      child: imagen ??
          Center(
            child: Text(
              app.nombre.isEmpty ? '?' : app.nombre.characters.first,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colores.primaryStrongText,
                  ),
            ),
          ),
    );
  }
}

class _Permiso extends StatelessWidget {
  const _Permiso({required this.onAbrir, required this.onRefrescar});

  final VoidCallback onAbrir;
  final VoidCallback onRefrescar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AvisoPrivacidad(),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.query_stats,
                      color: context.colores.primaryStrongText,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Falta el permiso «Acceso al uso»',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Android necesita este permiso para mostrar cuánto tiempo '
                  'estuvo abierta cada app. BlueTalk no lee mensajes, '
                  'pantallas ni contenido, y no envía nada a internet.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: onAbrir,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir Ajustes de Android'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onRefrescar,
                  child: const Text('Ya lo activé: actualizar'),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'En Ajustes, busca BlueTalk en la lista de apps y activa '
            '«Acceso al uso». Android no permite que BlueTalk active este '
            'permiso por su cuenta: lo concede el adulto.',
          ),
        ),
      ],
    );
  }
}

/// Detalle técnico para el adulto: qué se cuenta y qué no.
class _DetalleTecnico extends StatelessWidget {
  const _DetalleTecnico();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del cálculo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'Qué se cuenta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'El tiempo que cada app con pantalla de inicio estuvo en primer '
            'plano. Se excluyen BlueTalk, la pantalla de inicio y los '
            'servicios del sistema. Se muestran las 25 apps con más tiempo; '
            'el total incluye todas las apps con lanzador.',
          ),
          SizedBox(height: 16),
          Text(
            'Qué no se cuenta',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Pantalla apagada, notificaciones, segundo plano, mensajes, '
            'textos dentro de las apps, historial de búsquedas o páginas '
            'visitadas. BlueTalk no puede leer eso con este permiso.',
          ),
          SizedBox(height: 16),
          Text(
            'Precisión',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Android puede redondear o perder eventos si el teléfono se '
            'reinicia. Tómalo como una orientación, no como una medición '
            'exacta ni como un diagnóstico.',
          ),
        ],
      ),
    );
  }
}
