import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../app/models/shop_models.dart';
import '../../app/state/shop_state.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.fontSize = 32});
  final double fontSize;

  static const assetPath = 'assets/public/logo.png';

  @override
  Widget build(BuildContext context) {
    final markSize = fontSize * 1.35;
    return Semantics(
      label: 'platanitos',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: markSize,
              height: markSize,
              filterQuality: FilterQuality.high,
            ),
            SizedBox(width: fontSize / 8),
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
}

class ShopImage extends StatelessWidget {
  const ShopImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.thumbnail = false,
    this.semanticLabel,
  });
  final String url;
  final BoxFit fit;

  /// Descarga y decodifica la foto según el tamaño en que se muestra.
  final bool thumbnail;
  final String? semanticLabel;

  static final _unsplashPhoto = RegExp(
    r'images\.unsplash\.com/photo-([A-Za-z0-9_-]+)',
  );

  /// Unsplash no abre desde esta red. El proxy descarga la misma foto
  /// (la que corresponde al tipo de producto) y la entrega desde otro host.
  String _reachable(String source, int width) {
    if (_unsplashPhoto.firstMatch(source) == null) return source;
    final uri = Uri.tryParse(source);
    if (uri == null || uri.host != 'images.unsplash.com') return source;
    final query = Map<String, String>.from(uri.queryParameters);
    query['w'] = '$width';
    query.putIfAbsent('fit', () => 'crop');
    query.putIfAbsent('q', () => '85');
    final upstream =
        'images.unsplash.com${uri.path}?${Uri(queryParameters: query).query}';
    return 'https://images.weserv.nl/?url=${Uri.encodeComponent(upstream)}&output=jpg';
  }

  @override
  Widget build(BuildContext context) => thumbnail
      ? LayoutBuilder(
          builder: (context, constraints) {
            final side = [
              constraints.maxWidth,
              constraints.maxHeight,
            ].where((value) => value.isFinite).fold(0.0, math.max);
            final pixels = side.isFinite && side > 0
                ? side * MediaQuery.devicePixelRatioOf(context) * 1.25
                : 800.0;
            final width = ((pixels / 200).ceil() * 200).clamp(200, 1200);
            return _image(_reachable(url, width), width);
          },
        )
      : _image(_reachable(url, 800), null);

  Widget _image(String source, int? cacheWidth) => Image.network(
    source,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    cacheWidth: cacheWidth,
    semanticLabel: semanticLabel,
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
const fieldBorderColor = Color(0xFFC9D0CC);
const hintColor = Color(0xFFA0A6AE);

/// Carril horizontal con flechas para ver todo el contenido.
class ScrollLane extends StatefulWidget {
  const ScrollLane({
    super.key,
    required this.builder,
    this.step = 220,
    this.height,
  });

  final Widget Function(BuildContext context, ScrollController controller)
  builder;
  final double step;
  final double? height;

  @override
  State<ScrollLane> createState() => _ScrollLaneState();
}

class _ScrollLaneState extends State<ScrollLane> {
  final _scroll = ScrollController();
  var _canBack = false;
  var _canForward = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_sync)
      ..dispose();
    super.dispose();
  }

  void _sync() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final back = position.pixels > 1;
    final forward = position.pixels < position.maxScrollExtent - 1;
    if (back == _canBack && forward == _canForward) return;
    setState(() {
      _canBack = back;
      _canForward = forward;
    });
  }

  Future<void> _page(double delta) async {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + delta).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    await _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lane = Row(
      children: [
        _LaneArrow(
          icon: Icons.chevron_left,
          enabled: _canBack,
          tooltip: 'Anterior',
          onPressed: () => _page(-widget.step),
        ),
        Expanded(child: widget.builder(context, _scroll)),
        _LaneArrow(
          icon: Icons.chevron_right,
          enabled: _canForward,
          tooltip: 'Siguiente',
          onPressed: () => _page(widget.step),
        ),
      ],
    );
    return widget.height == null
        ? lane
        : SizedBox(height: widget.height, child: lane);
  }
}

class _LaneArrow extends StatelessWidget {
  const _LaneArrow({
    required this.icon,
    required this.enabled,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: enabled ? onPressed : null,
    style: IconButton.styleFrom(
      minimumSize: const Size(40, 40),
      foregroundColor: enabled ? AppColors.darkGreen : AppColors.border,
      disabledForegroundColor: AppColors.border,
    ),
    icon: Icon(icon, size: 26),
  );
}

/// TabBar con el mismo patrón de flechas en paneles y catálogo.
class ShopTabBar extends StatelessWidget {
  const ShopTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = true,
  });

  final List<Widget> tabs;
  final TabController? controller;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final tabsController = controller ?? DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: tabsController,
      builder: (context, _) {
        final canBack = tabsController.index > 0;
        final canForward = tabsController.index < tabsController.length - 1;
        return Row(
          children: [
            _LaneArrow(
              icon: Icons.chevron_left,
              enabled: canBack,
              tooltip: 'Pestaña anterior',
              onPressed: () => tabsController.animateTo(tabsController.index - 1),
            ),
            Expanded(
              child: TabBar(
                controller: tabsController,
                isScrollable: isScrollable,
                tabAlignment: isScrollable ? TabAlignment.start : null,
                indicatorColor: AppColors.green,
                labelColor: AppColors.green,
                unselectedLabelColor: AppColors.muted,
                tabs: tabs,
              ),
            ),
            _LaneArrow(
              icon: Icons.chevron_right,
              enabled: canForward,
              tooltip: 'Pestaña siguiente',
              onPressed: () => tabsController.animateTo(tabsController.index + 1),
            ),
          ],
        );
      },
    );
  }
}

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
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Semantics(
            liveRegion: true,
            label: text,
            child: Text(text),
          ),
        ),
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
    final onSale = product.onSale;
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
                        child: ShopImage(product.image, thumbnail: true),
                      ),
                      if (onSale)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: OfferBadge(discount: product.discount),
                        ),
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
  const OfferBadge({super.key, this.discount = 0});
  final int discount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      discount > 0 ? '-$discount%' : 'OFERTA',
      style: const TextStyle(
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
    this.minHeight = 32,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final double minHeight;
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
          constraints: BoxConstraints(minHeight: minHeight),
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
  }) : sliver = false;

  /// Versión perezosa para listas largas dentro de un [CustomScrollView].
  const ProductGrid.sliver({
    super.key,
    required this.products,
    required this.onOpen,
    this.favoriteActions = false,
  }) : sliver = true;
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final bool favoriteActions, sliver;

  SliverGridDelegate _layout(BuildContext context, double width) {
    const spacing = 12.0;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final count = (width / (160 * scale)).floor().clamp(1, 4);
    final itemWidth = (width - spacing * (count - 1)) / count;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: count,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      mainAxisExtent:
          itemWidth * .9 + (112 + (favoriteActions ? 48 : 0)) * scale,
    );
  }

  Widget _card(BuildContext context, int index) => ProductCard(
    product: products[index],
    onOpen: () => onOpen(products[index]),
    favoriteActions: favoriteActions,
  );

  @override
  Widget build(BuildContext context) => sliver
      ? SliverLayoutBuilder(
          builder: (context, constraints) => SliverGrid.builder(
            itemCount: products.length,
            gridDelegate: _layout(context, constraints.crossAxisExtent),
            itemBuilder: _card,
          ),
        )
      : LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: _layout(context, constraints.maxWidth),
            itemBuilder: _card,
          ),
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
