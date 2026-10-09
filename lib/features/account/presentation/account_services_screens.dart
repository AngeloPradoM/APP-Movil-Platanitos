import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_theme.dart';
import '../../../core/validators.dart';
import '../../../data/mock_data.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/presentation/auth_screens.dart';

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });
  final String label, value;
  final String? caption;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.green,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(caption!, style: const TextStyle(color: Colors.white70)),
        ],
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    ),
  );
}

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

class GiftCardScreen extends StatefulWidget {
  const GiftCardScreen({super.key});
  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  final form = GlobalKey<FormState>();
  double amount = giftCardAmounts[1];
  String name = '', email = '', message = '';
  bool sending = false;

  Future<void> send() async {
    if (sending || !form.currentState!.validate()) return;
    if (!await requireLogin(context, AuthPrompt.account) || !mounted) return;
    setState(() => sending = true);
    try {
      final code = await ShopScope.of(context).sendGiftCard(
        amount: amount,
        recipientName: name.trim(),
        recipientEmail: email.trim(),
        message: message.trim(),
      );
      if (!mounted) return;
      await showInfo(
        context,
        'eGift Card enviada',
        'Código: $code\n\nEnviamos ${money(amount)} a ${email.trim()} (demostración, sin cobro ni correo real).',
      );
      if (!mounted) return;
      form.currentState!.reset();
      setState(() {
        name = '';
        email = '';
        message = '';
      });
    } on StateError catch (error) {
      if (mounted) feedback(context, error.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'eGift Card',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HighlightCard(
          label: 'platanitos eGift Card',
          value: money(amount),
          caption: name.trim().isEmpty ? 'Para alguien especial' : 'Para $name',
        ),
        const SectionTitle('Elige el monto'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: giftCardAmounts
              .map(
                (value) => ChoiceChip(
                  label: Text(money(value)),
                  selected: amount == value,
                  onSelected: (_) => setState(() => amount = value),
                ),
              )
              .toList(),
        ),
        const SectionTitle('¿Para quién es?'),
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre de quien recibe',
                ),
                validator: Validators.name,
                onChanged: (value) => setState(() => name = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Correo de quien recibe',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                onChanged: (value) => email = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mensaje (opcional)',
                ),
                maxLength: 120,
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: sending ? null : send,
                icon: const Icon(Icons.card_giftcard),
                label: Text(sending ? 'Enviando…' : 'Enviar eGift Card'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Envío simulado · No se realizan cobros.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Ubícanos',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Visítanos en nuestras tiendas de Lima.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ...ShopScope.of(context).storeLocations.map(
          (store) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  store.district,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(store.address),
                Text(store.hours, style: Theme.of(context).textTheme.bodySmall),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: '${store.address}, ${store.district}',
                        ),
                      );
                      if (context.mounted) {
                        feedback(context, 'Dirección copiada');
                      }
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar dirección'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Blog',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: ShopScope.of(context).articles
          .map(
            (article) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BlogArticleScreen(article: article),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        height: 160,
                        child: ShopImage(article.image),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${article.category.toUpperCase()} · ${article.readMinutes} min',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class BlogArticleScreen extends StatelessWidget {
  const BlogArticleScreen({super.key, required this.article});
  final BlogArticle article;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Blog',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(height: 200, child: ShopImage(article.image)),
        ),
        const SizedBox(height: 16),
        Text(
          '${article.category.toUpperCase()} · ${article.readMinutes} min de lectura',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(article.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(article.body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}

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
