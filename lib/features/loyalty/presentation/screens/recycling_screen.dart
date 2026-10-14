import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../auth/presentation/auth_flow.dart';

import '../../../../shared/widgets/info_cards.dart';

class ResiklaScreen extends StatelessWidget {
  const ResiklaScreen({super.key});

  Future<void> generateCode(BuildContext context) async {
    if (!await requireLogin(context, AuthPrompt.account) || !context.mounted) {
      return;
    }
    final String code;
    try {
      code = await ShopScope.of(context).registerRecycling();
    } on StateError catch (error) {
      if (context.mounted) feedback(context, error.message);
      return;
    }
    if (!context.mounted) return;
    await showInfo(
      context,
      'Tu código Resikla',
      '$code\n\nMuéstralo en caja junto con tu calzado usado. Sumamos ${ShopState.recyclingBonus} puntos a tu cuenta (demostración).',
    );
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Resikla',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const HighlightCard(
          label: 'Programa de reciclaje',
          value: 'Dale una segunda vida a tu calzado',
        ),
        const SectionTitle('¿Cómo funciona?'),
        ...[
          'Genera tu código Resikla desde la app.',
          'Lleva tu calzado usado, limpio y en pares, a cualquier tienda.',
          'Muestra tu código en caja y recibe ${ShopState.recyclingBonus} puntos.',
        ].indexed.map(
          (step) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.softGreen,
              child: Text(
                '${step.$1 + 1}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            title: Text(step.$2),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => generateCode(context),
          icon: const Icon(Icons.recycling),
          label: const Text('Generar código Resikla'),
        ),
      ],
    ),
  );
}
