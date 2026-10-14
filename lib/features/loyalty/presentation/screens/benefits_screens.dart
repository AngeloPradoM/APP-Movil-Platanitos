import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../app/models/shop_models.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';

import '../../../../shared/widgets/info_cards.dart';
import '../widgets/membership_progress.dart';
import './wallet_screen.dart';

class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return PageFrame(
      title: 'Puntos',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HighlightCard(
            label: 'Puntos disponibles',
            value: '${state.points}',
            caption: 'Nivel ${state.membership.label}',
          ),
          const SizedBox(height: 16),
          LevelProgress(lifetimePoints: state.lifetimePoints),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const WalletScreen()),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: const Text('Canjear en el monedero'),
          ),
          const SectionTitle('Cómo ganar puntos'),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shopping_bag_outlined, color: AppColors.green),
            title: Text('1 punto por cada S/ 1 en compras'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.recycling, color: AppColors.green),
            title: Text(
              '${ShopState.recyclingBonus} puntos por reciclar con Resikla',
            ),
          ),
          const SectionTitle('Historial'),
          if (state.orders.isEmpty)
            Text(
              'Tus compras sumarán puntos automáticamente.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...state.orders.map(
              (order) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Pedido #${order.id}'),
                subtitle: Text(shortDate(order.createdAt)),
                trailing: Text(
                  '+${order.total.floor()}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final current = state.membership;
    return PageFrame(
      title: 'Membresía',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          HighlightCard(
            label: 'Tu nivel actual',
            value: current.label,
            caption: '${state.lifetimePoints} puntos acumulados',
          ),
          const SizedBox(height: 16),
          LevelProgress(lifetimePoints: state.lifetimePoints),
          const SectionTitle('Niveles y beneficios'),
          ...MembershipLevel.values.map(
            (level) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: level == current ? AppColors.softGreen : Colors.white,
                border: Border.all(
                  color: level == current ? AppColors.green : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level == current
                        ? '${level.label} · Tu nivel'
                        : level.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Desde ${level.minPoints} puntos',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ...level.benefits.map((benefit) => Text('✓ $benefit')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
