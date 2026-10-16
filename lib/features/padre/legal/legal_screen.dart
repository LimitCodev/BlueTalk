import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import 'legal_controller.dart';
import 'textos_legales.dart';

/// Render de Términos y Privacidad con aceptación versionada (plan 05 §6).
///
/// Antes de aceptar es la primera pantalla del modo padre: el rechazo no
/// deja pasar. Después se consulta desde Control, ya con la fecha y la
/// versión registradas.
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({super.key, this.onSalir});

  /// Cierra el modo padre (la ruta raíz lo cambia el coordinador).
  final VoidCallback? onSalir;

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> {
  bool _consentimiento = false;

  @override
  Widget build(BuildContext context) {
    final aceptacion = ref.watch(legalProvider);
    final aceptado = aceptacion != null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Estado de la aceptación arriba: se ve sin desplazar nada.
        if (aceptado) _Aceptado(aceptacion: aceptacion),
        const SectionHeader('Términos y condiciones'),
        _Documento(texto: terminosYCondiciones),
        const SectionHeader('Política de privacidad'),
        _Documento(texto: politicaDePrivacidad),
        if (!aceptado)
          _Pendiente(
            consentimiento: _consentimiento,
            onCambio: (value) => setState(() => _consentimiento = value),
            onAceptar: () async {
              await ref.read(legalProvider.notifier).aceptar();
              // Al aceptar, `padreProvider` pasa solo a la pantalla del gate.
            },
            onRechazar: () async {
              await ref.read(legalProvider.notifier).rechazar();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sin aceptar los términos no puedes entrar al modo padre.',
                  ),
                ),
              );
            },
            onSalir: widget.onSalir,
          ),
      ],
    );
  }
}

/// Documento completo: secciones y párrafos, con scroll (lazy).
class _Documento extends StatelessWidget {
  const _Documento({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final lineas = parsearLineas(texto);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final linea in lineas)
            if (linea.tipo == LineaLegalTipo.encabezado)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  linea.texto,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryStrongText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              )
            else if (linea.tipo == LineaLegalTipo.vineta)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• ${linea.texto}'),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(linea.texto),
              ),
        ],
      ),
    );
  }
}

/// Estado ya aceptado: fecha, versión y consentimiento registrado.
class _Aceptado extends StatelessWidget {
  const _Aceptado({required this.aceptacion});

  final AceptacionLegal aceptacion;

  @override
  Widget build(BuildContext context) {
    final fecha = aceptacion.fecha;
    final textoFecha =
        '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aceptado el $textoFecha (versión ${aceptacion.version}).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Consentimiento parental registrado.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Bloque de consentimiento + botones (solo la primera vez).
class _Pendiente extends StatelessWidget {
  const _Pendiente({
    required this.consentimiento,
    required this.onCambio,
    required this.onAceptar,
    required this.onRechazar,
    required this.onSalir,
  });

  final bool consentimiento;
  final ValueChanged<bool> onCambio;
  final Future<void> Function() onAceptar;
  final Future<void> Function() onRechazar;
  final VoidCallback? onSalir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: consentimiento,
            onChanged: (valor) => onCambio(valor ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Soy padre, madre o tutor legal y acepto los Términos y la '
              'Política de privacidad, con consentimiento parental.',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed:
                consentimiento ? () => unawaited(onAceptar()) : null,
            child: const Text('Aceptar y continuar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => unawaited(onRechazar()),
            child: const Text('No acepto'),
          ),
          if (onSalir != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSalir,
              child: const Text('Salir del modo padre'),
            ),
          ],
        ],
      ),
    );
  }
}
