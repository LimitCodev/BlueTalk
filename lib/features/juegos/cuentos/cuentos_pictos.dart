import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';

/// Picto pequeño de portada en la lista.
class PictoChico extends StatelessWidget {
  const PictoChico({super.key, required this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: asset == null
          ? Icon(Icons.menu_book, color: context.colores.primaryStrong)
          : SvgPicture.asset(
              asset!,
              fit: BoxFit.contain,
              placeholderBuilder: (context) =>
                  const SizedBox(width: 44, height: 44),
            ),
    );
  }
}

/// Picto grande de la página.
class PictoGrande extends StatelessWidget {
  const PictoGrande({super.key, required this.picto});

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
            placeholderBuilder: (context) =>
                const SizedBox(width: 72, height: 72),
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
