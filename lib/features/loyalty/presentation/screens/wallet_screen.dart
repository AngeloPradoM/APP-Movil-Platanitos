import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';

import '../../../../shared/widgets/info_cards.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final canRedeem = state.points >= ShopState.pointsPerRedemption;
    return PageFrame(
      title: 'Monedero',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HighlightCard(
            label: 'Saldo disponible',
            value: money(state.walletBalance),
            caption: 'Tienes ${state.points} puntos para canjear',
          ),
          const SizedBox(height: 16),
          Text(
            'Cada ${ShopState.pointsPerRedemption} puntos equivalen a ${money(ShopState.redemptionValue)} de saldo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canRedeem
                ? () async {
                    try {
                      final amount = await state.redeemPoints();
                      if (context.mounted) {
                        feedback(
                          context,
                          'Agregamos ${money(amount)} a tu monedero',
                        );
                      }
                    } on StateError catch (error) {
                      if (context.mounted) feedback(context, error.message);
                    }
                  }
                : null,
            icon: const Icon(Icons.swap_horiz),
            label: Text(
              canRedeem
                  ? 'Canjear puntos'
                  : 'Necesitas ${ShopState.pointsPerRedemption} puntos',
            ),
          ),
          const SectionTitle('Movimientos'),
          if (state.walletMovements.isEmpty)
            Text(
              'Aún no tienes movimientos. Canjea tus puntos para sumar saldo.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...state.walletMovements.map(
              (movement) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.softGreen,
                  child: Icon(Icons.add, color: AppColors.green),
                ),
                title: Text(movement.description),
                subtitle: Text(shortDate(movement.date)),
                trailing: Text(
                  '+${money(movement.amount)}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Saldo de demostración: todavía no se aplica en el pago.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
