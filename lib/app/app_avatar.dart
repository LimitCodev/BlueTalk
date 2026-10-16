import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/app_colors.dart';
import '../features/onboarding/profile_controller.dart';
import 'di.dart';

/// Ruta del asset SVG del picto dado (null si aún no carga o no existe).
final avatarAssetProvider = FutureProvider.family<String?, String>((
  ref,
  pictoId,
) async {
  final picto = await ref.watch(pictogramRepoProvider).pictogram(pictoId);
  return picto?.asset;
});

/// Avatar circular del niño (`ChildProfile.avatarPicto`).
///
/// Mientras el asset carga (o si falla) se muestra un icono de respaldo:
/// nunca un hueco ni un spinner.
class AppAvatar extends ConsumerWidget {
  const AppAvatar({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pictoId = ref.watch(profileProvider)?.avatarPicto;
    final asset = pictoId == null
        ? null
        : ref.watch(avatarAssetProvider(pictoId)).value;

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.colores.primary,
      child: asset == null
          ? Icon(
              Icons.child_care,
              size: size * 0.7,
              color: context.colores.primaryStrong,
            )
          : SvgPicture.asset(
              asset,
              width: size * 0.8,
              height: size * 0.8,
              fit: BoxFit.contain,
            ),
    );
  }
}
