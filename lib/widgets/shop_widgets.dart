import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../shared/models/shop_models.dart';
import '../shared/state/shop_state.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.fontSize = 32});
  final double fontSize;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'platanitos',
    excludeSemantics: true,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(fontSize * 36 / 32, fontSize * 44 / 32),
            painter: const _BrandMarkPainter(),
          ),
          SizedBox(width: fontSize / 16),
          Text(
            'platanitos',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -fontSize / 26,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Isotipo dibujado: hojas de palmera sobre dos plátanos.
class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 36, size.height / 44);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink;
    const leaves = [
      (-2.75, Color(0xFF3FAE5A)),
      (-2.1, Color(0xFF2A8F47)),
      (-1.35, Color(0xFF3FAE5A)),
      (-0.55, Color(0xFF2A8F47)),
    ];
    for (final (angle, color) in leaves) {
      canvas
        ..save()
        ..translate(18, 17)
        ..rotate(angle);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(8, -6, 17, 0)
        ..quadraticBezierTo(8, 5, 0, 0)
        ..close();
      canvas
        ..drawPath(leaf, Paint()..color = color)
        ..drawPath(leaf, outline)
        ..restore();
    }
    final banana = Path()
      ..moveTo(10, 20)
      ..quadraticBezierTo(26, 21, 25, 31)
      ..quadraticBezierTo(20, 25, 10, 25)
      ..close();
    final yellow = Paint()..color = AppColors.yellow;
    canvas
      ..drawPath(banana, yellow)
      ..drawPath(banana, outline)
      ..save()
      ..translate(36, 11)
      ..scale(-1, 1);
    canvas
      ..drawPath(banana, yellow)
      ..drawPath(banana, outline)
      ..restore();
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) => false;
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

const softBackground = Color(0xFFF8F9FB);
const fieldBorderColor = Color(0xFFE2E5EA);
const hintColor = Color(0xFFA0A6AE);

/// Campo blanco con borde gris que se marca en verde al enfocarse.
InputDecoration fieldDecoration(String hint, {Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: fieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.4),
      ),
    );

Widget fieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
  ),
);

final primaryButtonStyle = FilledButton.styleFrom(
  backgroundColor: AppColors.darkGreen,
  minimumSize: const Size(0, 48),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
);

final secondaryButtonStyle = OutlinedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: AppColors.muted,
  minimumSize: const Size(0, 48),
  side: const BorderSide(color: fieldBorderColor),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
);

final outlineGreenButtonStyle = OutlinedButton.styleFrom(
  backgroundColor: Colors.white,
  foregroundColor: AppColors.darkGreen,
  minimumSize: const Size(0, 48),
  side: const BorderSide(color: AppColors.darkGreen, width: 1.2),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  textStyle: const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
);

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
    final onSale = product.oldPrice > product.price;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onOpen,
        overlayColor: _greenOverlay,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        image: true,
                        label: product.name,
                        child: ShopImage(product.image),
                      ),
                      if (onSale)
                        const Positioned(top: 8, left: 8, child: OfferBadge()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.brand.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    money(product.price),
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (onSale) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        money(product.oldPrice),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Visibility(
                visible: product.lowStock,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: const Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 5),
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '¡Pocas unidades!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.ink, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (favoriteActions)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => state.toggleFavorite(product.id),
                        child: const Text(
                          'Quitar',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: onOpen,
                        child: const Text('Ver producto'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'OFERTA',
      style: TextStyle(
        color: AppColors.ink,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

final _greenOverlay = WidgetStateProperty.resolveWith<Color?>((states) {
  if (states.contains(WidgetState.pressed)) {
    return AppColors.green.withValues(alpha: .12);
  }
  if (states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused)) {
    return AppColors.green.withValues(alpha: .06);
  }
  return null;
});

/// Pastilla de filtro: verde sólido cuando está activa y borde gris si no.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.darkGreen : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.darkGreen : const Color(0xFFE2E5EA),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        overlayColor: selected
            ? WidgetStatePropertyAll(Colors.white.withValues(alpha: .14))
            : _greenOverlay,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.ink,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
      const spacing = 12.0;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final count = (constraints.maxWidth / (160 * scale)).floor().clamp(1, 4);
      final itemWidth = (constraints.maxWidth - spacing * (count - 1)) / count;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent:
              itemWidth * .9 + (112 + (favoriteActions ? 48 : 0)) * scale,
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
    this.trailing,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  /// Reemplaza el botón "Buscar" por acciones propias (voz, escáner…).
  final List<Widget>? trailing;
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
      hintStyle: widget.trailing == null ? null : const TextStyle(fontSize: 14),
      prefixIcon: const Icon(Icons.search),
      suffixIcon: widget.trailing == null
          ? IconButton(
              tooltip: 'Buscar',
              onPressed: widget.onSubmit,
              icon: const Icon(Icons.chevron_right),
            )
          : Row(mainAxisSize: MainAxisSize.min, children: widget.trailing!),
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
  Widget build(BuildContext context) {
    final steps = [
      (
        'Preparación',
        Icons.inventory_2_outlined,
        'Pago confirmado con ${order.payment.shortLabel}',
        'Pago confirmado con ${order.payment.shortLabel}',
      ),
      (
        'Despacho',
        Icons.outbox_outlined,
        'Salió del almacén',
        'Pendiente de salir del almacén',
      ),
      (
        'En camino',
        Icons.local_shipping_outlined,
        'En ruta hacia tu dirección',
        'Pendiente de iniciar el traslado',
      ),
      (
        'Entrega',
        Icons.home_outlined,
        'Pedido entregado',
        'Pendiente de confirmación',
      ),
    ];
    return Column(
      children: List.generate(steps.length, (index) {
        final (label, icon, doneText, pendingText) = steps[index];
        final current = index == order.status.index;
        final done = index < order.status.index;
        final reached = current || done;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: current ? 28 : 22,
                      height: current ? 28 : 22,
                      margin: EdgeInsets.symmetric(vertical: current ? 0 : 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: current
                            ? AppColors.darkGreen
                            : done
                            ? AppColors.softGreen
                            : Colors.white,
                        border: Border.all(
                          color: reached
                              ? AppColors.darkGreen
                              : fieldBorderColor,
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        current ? icon : (done ? Icons.check : Icons.circle),
                        color: current
                            ? Colors.white
                            : done
                            ? AppColors.darkGreen
                            : fieldBorderColor,
                        size: current ? 15 : (done ? 13 : 6),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 1.4,
                          color: done ? AppColors.darkGreen : fieldBorderColor,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    current ? 2 : 3,
                    0,
                    index < steps.length - 1 ? 18 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: reached
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 13.5,
                                color: current
                                    ? AppColors.darkGreen
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                          if (current)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Actual',
                                style: TextStyle(
                                  color: AppColors.darkGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reached ? doneText : pendingText,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
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
}
