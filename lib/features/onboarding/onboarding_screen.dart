import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'profile_controller.dart';

/// Onboarding (plan 01 §7): "Tu voz, siempre contigo 💙" → apodo local
/// (sin PII, solo se guarda en el teléfono) → home.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nicknameController = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canStart => _nicknameController.text.trim().isNotEmpty && !_saving;

  Future<void> _start() async {
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).create(_nicknameController.text);
    if (!mounted) return;
    context.go('/home/comunicar');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'BlueTalk',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu voz, siempre contigo 💙',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nicknameController,
                    enabled: !_saving,
                    autofocus: true,
                    maxLength: 20,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_canStart) _start();
                    },
                    decoration: const InputDecoration(
                      labelText: '¿Cómo te llamas?',
                      hintText: 'Escribe un apodo',
                      helperText:
                          'Un apodo, o el de tu hijo/a. No hace falta un '
                          'nombre real.',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El apodo se guarda solo en este teléfono.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _canStart ? _start : null,
                    child: const Text('Comenzar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
