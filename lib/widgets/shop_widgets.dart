import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../shared/models/shop_models.dart';
import '../shared/state/shop_state.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});
  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      text: 'platanitos',
      style: TextStyle(
        color: AppColors.green,
        fontSize: 29,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
      ),
      children: [
        TextSpan(
          text: '●',
          style: TextStyle(color: AppColors.yellow, fontSize: 12),
        ),
      ],
    ),
  );
}

class ShopImage extends StatelessWidget {
  const ShopImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : const ColoredBox(
            color: AppColors.background,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
    errorBuilder: (context, error, stack) => const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.muted,
          size: 38,
        ),
      ),
    ),
  );
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.actions,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            child: Padding(padding: const EdgeInsets.all(16), child: bottom),
          ),
  );
}

void feedback(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
Future<void> showInfo(BuildContext context, String title, String message) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.softGreen,
            child: Icon(icon, size: 36, color: AppColors.green),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onOpen,
    this.favoriteActions = false,
  });
  final Product product;
  final VoidCallback onOpen;
  final bool favoriteActions;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final favorite = state.signedIn && state.favorites.contains(product.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Semantics(
                  button: true,
                  label: 'Ver ${product.name}',
                  child: InkWell(
                    onTap: onOpen,
                    child: ShopImage(product.image),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'OFERTA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    tooltip: favorite
                        ? 'Quitar de favoritos'
                        : 'Agregar a favoritos',
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () =>
                        toggleFavoriteWithLogin(context, product.id),
                    icon: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  money(product.oldPrice),
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  money(product.price),
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                if (product.lowStock)
                  const Text(
                    '¡Pocas unidades!',
                    style: TextStyle(color: AppColors.darkGreen, fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
        if (favoriteActions)
          Wrap(
            children: [
              TextButton(
                onPressed: () => state.toggleFavorite(product.id),
                child: const Text(
                  'Quitar',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),

              TextButton(onPressed: onOpen, child: const Text('Ver producto')),
            ],
          ),
      ],
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
    this.favoriteActions = false,
  });
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final bool favoriteActions;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final count = (constraints.maxWidth / (150 * scale)).floor().clamp(1, 4);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 22,
          mainAxisExtent: 300 + (favoriteActions ? 96 : 0) + (scale - 1) * 130,
        ),
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onOpen: () => onOpen(products[index]),
          favoriteActions: favoriteActions,
        ),
      );
    },
  );
}

class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmit,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController controller = TextEditingController(
    text: widget.value,
  );
  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller.text != widget.value) {
      controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: widget.onChanged,
    onSubmitted: (_) => widget.onSubmit(),
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: '¿Qué estás buscando hoy?',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        onPressed: widget.onSubmit,
        icon: const Icon(Icons.chevron_right),
      ),
    ),
  );
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.subtotal,
    required this.shipping,
  });
  final double subtotal, shipping;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        row('Subtotal', money(subtotal)),
        const SizedBox(height: 12),
        row('Envío', money(shipping)),
        const Divider(height: 28),
        row('Total', money(subtotal + shipping), bold: true),
      ],
    ),
  );
  Widget row(String label, String value, {bool bold = false}) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        value,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          color: bold ? AppColors.green : AppColors.ink,
        ),
      ),
    ],
  );
}

class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(4, (index) {
      final complete = index <= order.status.index;
      final label = ['Preparación', 'Despacho', 'En camino', 'Entrega'][index];
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 42,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: complete
                        ? AppColors.green
                        : AppColors.background,
                    child: Icon(
                      complete ? Icons.check : Icons.circle_outlined,
                      color: complete ? Colors.white : AppColors.muted,
                      size: 18,
                    ),
                  ),
                  if (index < 3)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: complete ? AppColors.green : AppColors.border,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 0, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      index == order.status.index
                          ? 'Estado actual'
                          : complete
                          ? 'Completado'
                          : 'Pendiente',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }),
  );
}
