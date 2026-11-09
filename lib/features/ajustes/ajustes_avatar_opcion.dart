import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_avatar.dart';
import '../../core/theme/app_colors.dart';
import '../onboarding/profile_controller.dart';

/// Opción de avatar: círculo táctil de 56dp (≥48 del plan 00 §5) con
/// borde fuerte cuando está seleccionada.
class AvatarOption extends ConsumerWidget {
  const AvatarOption({
    super.key,
    required this.pictoId,
    required this.label,
    required this.selected,
  });

  final String pictoId;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(avatarAssetProvider(pictoId)).value;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Avatar $label',
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => ref.read(profileProvider.notifier).updateAvatar(pictoId),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colores.primary,
              border: Border.all(
                color: selected
                    ? context.colores.primaryStrong
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: asset == null
                ? Icon(
                    Icons.child_care,
                    size: 30,
                    color: context.colores.primaryStrong,
                  )
                : SvgPicture.asset(asset, width: 40, height: 40),
          ),
        ),
      ),
    );
  }
}
