import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../cart/presentation/cart_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final gallery = PageController();
  SizeSystem system = SizeSystem.eur;
  int? sizeIndex;
  int imageIndex = 0;
  @override
  void dispose() {
    gallery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), product = widget.product;
    final images = [product.image, ...galleryImages];
    return PageFrame(
      title: 'Detalle',
      actions: [
        IconButton(
          tooltip: 'Ver bolsa',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CartPage()),
          ),
          icon: Badge(
            label: Text('${state.cartCount}'),
            isLabelVisible: state.cartCount > 0,
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
      ],
      bottom: FilledButton.icon(
        onPressed: () {
          if (sizeIndex == null) {
            feedback(
              context,
              'Selecciona una talla antes de agregar a la bolsa.',
            );
            return;
          }
          try {
            state.addToCart(product, sizeIndex!, system);
          } on ArgumentError catch (error) {
            feedback(context, '${error.message}');
            return;
          }
          feedback(context, 'Producto agregado a tu bolsa');
        },
        icon: const Icon(Icons.shopping_bag_outlined),
        label: const Text('Agregar a la Bolsa'),
      ),
      child: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Stack(
              children: [
                PageView.builder(
                  controller: gallery,
                  itemCount: images.length,
                  onPageChanged: (value) => setState(() => imageIndex = value),
                  itemBuilder: (_, index) => ShopImage(images[index]),
                ),
                Positioned(
                  top: 10,
                  left: 18,
                  child: Chip(
                    backgroundColor: AppColors.yellow,
                    label: Text('OFERTA −${product.discount}%'),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: IconButton.filledTonal(
                    tooltip: 'Cambiar favorito',
                    onPressed: () => state.toggleFavorite(product.id),
                    icon: Icon(
                      state.favorites.contains(product.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.green,
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 150,
                  child: IconButton.filledTonal(
                    tooltip: 'Imagen anterior',
                    onPressed: () => gallery.animateToPage(
                      (imageIndex + images.length - 1) % images.length,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 150,
                  child: IconButton.filledTonal(
                    tooltip: 'Siguiente imagen',
                    onPressed: () => gallery.animateToPage(
                      (imageIndex + 1) % images.length,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: index == imageIndex
                              ? AppColors.green
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'SKU 1000${product.id} · Color ${product.color}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money(product.price),
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      money(product.oldPrice),
                      style: const TextStyle(
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Chip(
                      label: Text('−${product.discount}%'),
                      backgroundColor: AppColors.softGreen,
                    ),
                  ],
                ),
                const Text(
                  'Hasta 3 cuotas sin intereses con tarjetas seleccionadas',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    const Text(
                      'Elige tu talla',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => showInfo(
                        context,
                        'Guía de tallas',
                        'Mide tu pie desde el talón hasta la punta. Para 23.5 cm recomendamos talla 37 EUR / 7 US.',
                      ),
                      child: const Text('Guía de tallas'),
                    ),
                  ],
                ),
                SegmentedButton<SizeSystem>(
                  showSelectedIcon: false,
                  segments: SizeSystem.values
                      .map(
                        (value) => ButtonSegment(
                          value: value,
                          label: Text(value.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  selected: {system},
                  onSelectionChanged: (values) =>
                      setState(() => system = values.first),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    6,
                    (index) => ChoiceChip(
                      label: Text(sizeLabels[system]![index]),
                      selected: sizeIndex == index,
                      onSelected: product.availableSizes.contains(index)
                          ? (_) => setState(() => sizeIndex = index)
                          : null,
                    ),
                  ),
                ),
                if (product.lowStock)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '¡Últimas unidades disponibles!',
                      style: TextStyle(color: AppColors.darkGreen),
                    ),
                  ),
                const SizedBox(height: 20),
                DeliveryOption(
                  icon: Icons.local_shipping_outlined,
                  title: 'Delivery a domicilio',
                  description: 'Ingresa tu ubicación para calcular la fecha',
                  action: 'Calcular envío',
                  onTap: () => showInfo(
                    context,
                    'Envío estimado a Lima',
                    'Entrega en 6–8 días · S/ 6.90. Información simulada.',
                  ),
                ),
                const SizedBox(height: 12),
                DeliveryOption(
                  icon: Icons.location_on_outlined,
                  title: 'Recojo gratis en tienda',
                  description: 'Disponible en tiendas seleccionadas',
                  action: 'Ver tiendas',
                  onTap: () => showInfo(
                    context,
                    'Tiendas disponibles',
                    'Platanitos Jockey Plaza, Centro Cívico y San Miguel. Consulta de demostración.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryOption extends StatelessWidget {
  const DeliveryOption({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final String title, description, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
              TextButton(onPressed: onTap, child: Text(action)),
            ],
          ),
        ),
      ],
    ),
  );
}
