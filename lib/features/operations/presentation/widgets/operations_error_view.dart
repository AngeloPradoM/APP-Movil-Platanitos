import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class OperationsErrorView extends StatelessWidget {
  const OperationsErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 72),
      const Icon(
        Icons.sync_problem_outlined,
        size: 52,
        color: AppColors.muted,
      ),
      const SizedBox(height: 16),
      const Text(
        'No se pudieron cargar los datos locales.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3D4550),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Vuelve a intentarlo. Los datos guardados no se eliminarán.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 20),
      Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
    ],
  );
}
