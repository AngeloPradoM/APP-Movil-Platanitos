import 'package:flutter/material.dart';

import '../../../../app/models/shop_models.dart';

class LevelProgress extends StatelessWidget {
  const LevelProgress({super.key, required this.lifetimePoints});
  final int lifetimePoints;
  @override
  Widget build(BuildContext context) {
    final level = MembershipLevel.forPoints(lifetimePoints);
    final next = level.next;
    if (next == null) {
      return const Text(
        'Alcanzaste el nivel más alto. ¡Gracias por elegirnos!',
      );
    }
    final progress =
        (lifetimePoints - level.minPoints) / (next.minPoints - level.minPoints);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress.clamp(0, 1).toDouble(),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text(
          'Te faltan ${next.minPoints - lifetimePoints} puntos para el nivel ${next.label}.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
