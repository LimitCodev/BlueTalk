import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Banner obligatorio: hasta que haya sync real, todo aquí es demostración.
class BannerDemo extends StatelessWidget {
  const BannerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: AppColors.onWarning, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datos de demostración',
                  style: TextStyle(
                    color: AppColors.onWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Métricas calculadas localmente en este dispositivo. '
                  'Todavía no hay sincronización con la nube.',
                  style: TextStyle(color: AppColors.onWarning, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
