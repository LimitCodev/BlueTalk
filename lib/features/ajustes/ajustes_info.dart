import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/section_header.dart';

/// Acceso discreto a la zona de adultos: el PIN lo pide el gate, no aquí.
class ZonaAdultosSection extends StatelessWidget {
  const ZonaAdultosSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Zona de adultos'),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Modo padre'),
          subtitle: const Text('Resumen, control y legal. Pide tu código.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/padre'),
        ),
      ],
    );
  }
}

class LegalSection extends StatelessWidget {
  const LegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Legal'),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Términos y condiciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPlaceholder(context, 'Términos y condiciones'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de privacidad'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPlaceholder(context, 'Política de privacidad'),
        ),
      ],
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Este contenido estará disponible en una versión futura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Créditos de los pictogramas (licencia obligatoria).
class CreditsSection extends StatelessWidget {
  const CreditsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Créditos'),
        ListTile(
          title: Text('Pictogramas: Mulberry Symbols'),
          subtitle: Text('© Mulberry Project — licencia CC BY-SA 4.0'),
        ),
      ],
    );
  }
}
