import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/line_icons.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../cart/presentation/cart_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final gallery = PageController();
  late SizeSystem system = widget.product.sizeSystem;
  late int? sizeIndex = oneSize && widget.product.availableSizes.contains(0)
      ? 0
      : null;
  int imageIndex = 0;
  bool get oneSize => widget.product.sizeSystem == SizeSystem.oneSize;
  @override
  void dispose() {
    gallery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), product = widget.product;
    final images = [product.image, ...galleryImages];
    final soldOut = product.availableSizes.isEmpty;
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
            child: const LineIcon(LineIcons.bag),
          ),
        ),
      ],
      bottom: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkGreen,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: soldOut
            ? null
            : () {
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
        icon: const LineIcon(LineIcons.bag, size: 20),
        label: Text(soldOut ? 'Producto agotado' : 'Agregar a la Bolsa'),
      ),
      child: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Stack(
              children: [
                ColoredBox(
                  color: AppColors.background,
                  child: PageView.builder(
                    controller: gallery,
                    itemCount: images.length,
                    onPageChanged: (value) =>
                        setState(() => imageIndex = value),
                    itemBuilder: (_, index) => ShopImage(images[index]),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    tooltip: 'Cambiar favorito',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .92),
                    ),
                    onPressed: () =>
                        toggleFavoriteWithLogin(context, product.id),
                    icon: state.signedIn && state.favorites.contains(product.id)
                        ? const Icon(Icons.favorite, color: AppColors.darkGreen)
                        : const LineIcon(LineIcons.heart, size: 22),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Semantics(
                        button: true,
                        selected: index == imageIndex,
                        label: 'Imagen ${index + 1} de ${images.length}',
                        child: InkResponse(
                          radius: 14,
                          onTap: () => gallery.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == imageIndex
                                    ? AppColors.ink.withValues(alpha: .55)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money(product.price),
                      style: const TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (product.onSale) ...[
                      Text(
                        money(product.oldPrice),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      OfferBadge(discount: product.discount),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hasta 3 cuotas sin intereses con tarjetas seleccionadas',
                  style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 18),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      oneSize ? 'Talla' : 'Elige tu talla',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!oneSize)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.darkGreen,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => showInfo(
                          context,
                          'Guía de tallas',
                          product.sizeSystem == SizeSystem.alpha
                              ? 'Mide tu contorno de pecho, cintura y cadera y compáralo con tu talla habitual. Si estás entre dos tallas, elige la mayor.'
                              : 'Mide tu pie desde el talón hasta la punta. Para 23.5 cm recomendamos talla 37 EUR / 7 US.',
                        ),
                        child: const Text('Guía de tallas'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (product.convertible) ...[
                  SizeSystemTabs(
                    systems: product.sizeSystems,
                    value: system,
                    onChanged: (value) => setState(() => system = value),
                  ),
                  const SizedBox(height: 14),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    final cell = product.sizes.any((size) => size.length > 3)
                        ? 72.0
                        : 56.0;
                    final columns = (constraints.maxWidth / (cell * scale))
                        .floor()
                        .clamp(3, 6);
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: List.generate(
                        product.sizes.length,
                        (index) => SizedBox(
                          width: width,
                          child: SizeBox(
                            label: product.sizeLabel(index, system),
                            selected: sizeIndex == index,
                            onTap: product.availableSizes.contains(index)
                                ? () => setState(() => sizeIndex = index)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (product.lowStock)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(dimension: 6),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '¡Últimas unidades disponibles!',
                            style: TextStyle(
                              color: AppColors.darkGreen,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
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

class SizeSystemTabs extends StatelessWidget {
  const SizeSystemTabs({
    super.key,
    required this.value,
    required this.onChanged,
    this.systems = const [SizeSystem.eur, SizeSystem.us, SizeSystem.cm],
  });
  final SizeSystem value;
  final ValueChanged<SizeSystem> onChanged;
  final List<SizeSystem> systems;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        for (final system in systems)
          Expanded(
            child: Semantics(
              button: true,
              selected: system == value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: system == value ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: system == value
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: AppColors.green.withValues(alpha: .06),
                    onTap: () => onChanged(system),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Center(
                        child: Text(
                          system.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: system == value
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: system == value
                                ? AppColors.darkGreen
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Caja cuadrada de talla; sin [onTap] se muestra agotada.
class SizeBox extends StatelessWidget {
  const SizeBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: available,
      label: available ? 'Talla $label' : 'Talla $label agotada',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.darkGreen
            : available
            ? Colors.white
            : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.darkGreen : const Color(0xFFE2E5EA),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: AppColors.green.withValues(alpha: .08),
          splashColor: AppColors.green.withValues(alpha: .14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : available
                        ? AppColors.ink
                        : AppColors.muted,
                    decoration: available ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ),
          ),
        ),
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
