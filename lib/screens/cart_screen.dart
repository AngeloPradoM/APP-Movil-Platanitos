import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import 'checkout_screen.dart';
import 'catalog_screens.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Mi Bolsa',
    child: CartScreen(
      onCatalog: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              const PageFrame(title: 'Calzado', child: CatalogScreen()),
        ),
      ),
    ),
  );
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    if (state.cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Tu bolsa está vacía',
        message: 'Encuentra algo especial para ti.',
        action: 'Explorar productos',
        onAction: onCatalog,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        ...state.cart.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 85,
                      height: 105,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ShopImage(item.product.image),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Talla: ${item.size} · ${item.system.name.toUpperCase()} · ${item.product.color}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            money(item.product.price),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Disminuir cantidad',
                                onPressed: () => state.changeQuantity(item, -1),
                                icon: const Icon(Icons.remove, size: 18),
                              ),
                              Text('${item.quantity}'),
                              IconButton(
                                tooltip: 'Aumentar cantidad',
                                onPressed: () => state.changeQuantity(item, 1),
                                icon: const Icon(Icons.add, size: 18),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar producto',
                      onPressed: () => state.removeItem(item),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.green),
              SizedBox(width: 10),
              Expanded(child: Text('Envío estimado a Lima')),
              Text('S/ 6.90', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SummaryCard(subtotal: state.subtotal, shipping: state.shipping),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
          ),
          child: const Text('Ir a Pagar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onCatalog,
          child: const Text('Seguir comprando'),
        ),
      ],
    );
  }
}
