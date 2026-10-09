import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/presentation/auth_screens.dart';
import 'product_screen.dart';

void openProduct(BuildContext context, Product product) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => ProductScreen(product: product)),
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const sections = ['Calzado', 'Carteras', 'Ofertas', 'Accesorios'];
  static const _bags = ['cartera', 'bolso', 'mochila'];
  static const _accessories = ['accesorio', 'reloj', 'correa', 'billetera'];
  int section = 0;

  List<Product> sectionProducts(List<Product> source) {
    bool inCategory(Product product, List<String> words) {
      final category = product.category.toLowerCase();
      return words.any(category.contains);
    }

    return source
        .where(
          (product) => switch (section) {
            1 => inCategory(product, _bags),
            2 => product.onSale,
            3 => inCategory(product, _accessories),
            _ => product.sizeSystem == SizeSystem.eur,
          },
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final recommended = sectionProducts(state.catalogProducts);
    return ColoredBox(
      color: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchField(
                    value: state.catalog.query,
                    onChanged: (value) {
                      state.catalog.query = value;
                      state.updateCatalog();
                    },
                    onSubmit: widget.onCatalog,
                    trailing: [
                      IconButton(
                        tooltip: 'Buscar por voz',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => feedback(
                          context,
                          'La búsqueda por voz estará disponible pronto.',
                        ),
                        icon: const Icon(Icons.mic_none),
                      ),
                      IconButton(
                        tooltip: 'Escanear producto',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => feedback(
                          context,
                          'El escáner de productos estará disponible pronto.',
                        ),
                        icon: const Icon(Icons.crop_free),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SectionTabs(
                    labels: sections,
                    selected: section,
                    onSelected: (index) => setState(() => section = index),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HomeBanners(onTap: widget.onCatalog),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recomendados para ti',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: widget.onCatalog,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (recommended.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Pronto tendremos novedades en ${sections[section]}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            RecommendedCarousel(
              products: recommended,
              onOpen: (product) => openProduct(context, product),
            ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                ListBenefit(
                  icon: Icons.local_shipping_outlined,
                  title: 'Envíos a todo el Perú',
                  subtitle: 'Recibe donde estés',
                ),
                ListBenefit(
                  icon: Icons.credit_card,
                  title: 'Compra 100% segura',
                  subtitle: 'Pagos simulados en esta demo',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class SectionTabs extends StatelessWidget {
  const SectionTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (index, label) in labels.indexed)
          Semantics(
            selected: index == selected,
            button: true,
            child: InkWell(
              onTap: () => onSelected(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 18),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: index == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: index == selected
                                ? AppColors.darkGreen
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: index == selected
                              ? AppColors.darkGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class HomeBanners extends StatefulWidget {
  const HomeBanners({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<HomeBanners> {
  static final slides = [
    (bannerImage, 'Cyber Days 50% Off', 'Exclusivo en Calzado y Carteras'),
    (galleryImages[0], 'Nueva temporada', 'Botines y tacos para cada ocasión'),
    (galleryImages[1], 'Gana puntos', 'Acumula 1 punto por cada S/ 1'),
  ];
  final controller = PageController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height:
                (constraints.maxWidth / 2.25).clamp(130, 260) +
                (scale - 1) * 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (context, index) {
                  final (image, title, subtitle) = slides[index];
                  return Semantics(
                    button: true,
                    label: '$title. $subtitle',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ShopImage(image),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [Color(0xCC000000), Colors.transparent],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.yellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < slides.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == page
                      ? AppColors.darkGreen
                      : const Color(0xFFC9CED4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class RecommendedCarousel extends StatelessWidget {
  const RecommendedCarousel({
    super.key,
    required this.products,
    required this.onOpen,
  });
  final List<Product> products;
  final ValueChanged<Product> onOpen;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: 236 + (scale - 1) * 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 160 + (scale - 1) * 40,
          child: RecommendedCard(
            product: products[index],
            onOpen: () => onOpen(products[index]),
          ),
        ),
      ),
    );
  }
}

class RecommendedCard extends StatelessWidget {
  const RecommendedCard({
    super.key,
    required this.product,
    required this.onOpen,
  });
  final Product product;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: AppColors.background,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ShopImage(product.image),
                      if (product.onSale)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: OfferBadge(discount: product.discount),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 2),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: money(product.price),
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (product.onSale) ...[
                    const TextSpan(text: '  '),
                    TextSpan(
                      text: money(product.oldPrice),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ListBenefit extends StatelessWidget {
  const ListBenefit({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.green),
      const SizedBox(width: 10),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ShopScope.of(context).loadRemoteCatalog();
    });
  }

  Future<void> apply() async {
    setState(() => loading = true);
    ShopScope.of(context).updateCatalog();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => loading = false);
  }

  static const _prices = [double.infinity, 100.0, 200.0, 300.0, 500.0];
  static const _sorts = [
    ProductSort.recommended,
    ProductSort.cheapest,
    ProductSort.expensive,
  ];

  String _sortLabel(ProductSort sort) => switch (sort) {
    ProductSort.cheapest => 'Menor precio',
    ProductSort.expensive => 'Mayor precio',
    _ => 'Recomendados',
  };

  /// Muestra las opciones como pastillas y devuelve la elegida, o `null` si
  /// se cierra sin elegir. Con [fromCatalog] las opciones se actualizan
  /// mientras llegan las páginas restantes del catálogo.
  Future<String?> choose(
    String title,
    List<String> Function(ShopState state) options,
    String selected, {
    bool fromCatalog = false,
  }) {
    if (fromCatalog) ShopScope.of(context).loadFullCatalog();
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final state = ShopScope.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (fromCatalog && state.catalogLoadingMore) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final option in options(state))
                    FilterPill(
                      label: option,
                      selected: option == selected,
                      onTap: () => Navigator.pop(context, option),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static List<String> _distinct(Iterable<String> values) =>
      values.toSet().toList()..sort();

  Future<void> pickSize() async {
    final filter = ShopScope.of(context).catalog;
    final choice = await choose(
      'Talla',
      (state) => [
        'Todas',
        ...{
          for (final product in state.catalogProducts)
            if (product.sizeSystem != SizeSystem.oneSize) ...product.sizes,
        }.toList()..sort(compareSizes),
      ],
      filter.size ?? 'Todas',
      fromCatalog: true,
    );
    if (choice == null || !mounted) return;
    filter.size = choice == 'Todas' ? null : choice;
    await apply();
  }

  Future<void> pickBrand() async {
    final filter = ShopScope.of(context).catalog;
    final choice = await choose(
      'Marca',
      (state) => [
        'Todas',
        ..._distinct(state.catalogProducts.map((p) => p.brand)),
      ],
      filter.brand ?? 'Todas',
      fromCatalog: true,
    );
    if (choice == null || !mounted) return;
    filter.brand = choice == 'Todas' ? null : choice;
    await apply();
  }

  Future<void> pickColor() async {
    final filter = ShopScope.of(context).catalog;
    final choice = await choose(
      'Color',
      (state) => [
        'Todos',
        ..._distinct(state.catalogProducts.map((p) => p.color)),
      ],
      filter.color ?? 'Todos',
      fromCatalog: true,
    );
    if (choice == null || !mounted) return;
    filter.color = choice == 'Todos' ? null : choice;
    await apply();
  }

  Future<void> pickPrice() async {
    final filter = ShopScope.of(context).catalog;
    final labels = [
      'Todos',
      for (final price in _prices.skip(1)) 'Hasta ${money(price)}',
    ];
    final current = _prices.indexOf(filter.maxPrice);
    final choice = await choose(
      'Precio',
      (_) => labels,
      labels[current < 0 ? 0 : current],
    );
    if (choice == null || !mounted) return;
    filter.maxPrice = _prices[labels.indexOf(choice)];
    await apply();
  }

  Future<void> pickSort() async {
    final filter = ShopScope.of(context).catalog;
    final labels = _sorts.map(_sortLabel).toList();
    final choice = await choose(
      'Ordenar por',
      (_) => labels,
      _sortLabel(filter.sort),
    );
    if (choice == null || !mounted) return;
    filter.sort = _sorts[labels.indexOf(choice)];
    await apply();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), filter = state.catalog;
    final result = filter.apply(state.catalogProducts);
    return ColoredBox(
      color: AppColors.background,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.extentAfter < 600) {
            state.loadMoreCatalog();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _filters(filter)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverMainAxisGroup(
                slivers: _results(context, state, filter, result),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(CatalogFilter filter) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          FilterPill(
            label: filter.size == null ? 'Talla' : 'Talla ${filter.size}',
            selected: filter.size != null,
            onTap: pickSize,
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: filter.brand ?? 'Marca',
            selected: filter.brand != null,
            onTap: pickBrand,
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: filter.color ?? 'Color',
            selected: filter.color != null,
            onTap: pickColor,
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: filter.maxPrice.isFinite
                ? 'Hasta ${money(filter.maxPrice)}'
                : 'Precio',
            selected: filter.maxPrice.isFinite,
            onTap: pickPrice,
          ),
          const SizedBox(width: 8),
          FilterPill(
            label: filter.sort == ProductSort.recommended
                ? 'Ordenar'
                : _sortLabel(filter.sort),
            icon: Icons.swap_vert,
            selected: filter.sort != ProductSort.recommended,
            onTap: pickSort,
          ),
        ],
      ),
    ),
  );

  /// Pie del listado: carga en curso, error de página o "Ver más".
  Widget _footer(
    BuildContext context,
    ShopState state,
    CatalogFilter filter,
    int shown,
  ) {
    final small = Theme.of(context).textTheme.bodySmall;
    if (state.catalogLoadingMore) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }
    if (state.catalogMoreFailed) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Text(
              'El sistema está fallando en este momento. Intenta más tarde.',
              textAlign: TextAlign.center,
              style: small,
            ),
            TextButton(
              onPressed: state.retryCatalogPage,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!state.catalogHasMore || filter.isActive) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          Text(
            'Mostrando $shown de ${state.catalogTotal} productos',
            textAlign: TextAlign.center,
            style: small,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: state.loadMoreCatalog,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGreen,
              side: const BorderSide(color: AppColors.darkGreen),
            ),
            child: const Text('Ver más productos'),
          ),
        ],
      ),
    );
  }

  List<Widget> _results(
    BuildContext context,
    ShopState state,
    CatalogFilter filter,
    List<Product> result,
  ) {
    final searching =
        state.catalogLoadingMore ||
        (filter.isActive && state.catalogHasMore && !state.catalogMoreFailed);
    return [
      if (filter.query.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultados para “${filter.query}”',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${result.length} productos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    filter.query = '';
                    state.updateCatalog();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      if (state.catalogError != null)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'El sistema está fallando en este momento. Mostramos datos de respaldo.',
                  ),
                ),
                TextButton(
                  onPressed: state.loadRemoteCatalog,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      if (state.catalogLoading || loading || (result.isEmpty && searching))
        const SliverToBoxAdapter(child: CatalogSkeleton())
      else if (state.catalogError != null && state.catalogProducts.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.cloud_off,
            title: 'El sistema está presentando problemas',
            message: 'No pudimos cargar el catálogo en este momento. Intenta nuevamente.',
            action: 'Reintentar',
            onAction: state.loadRemoteCatalog,
          ),
        )
      else if (result.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search,
            title: 'No encontramos productos',
            message: 'Prueba con otra palabra o elimina los filtros.',
            action: 'Limpiar búsqueda y filtros',
            onAction: () {
              filter.clear();
              state.updateCatalog();
            },
          ),
        )
      else ...[
        ProductGrid.sliver(
          products: result,
          onOpen: (product) => openProduct(context, product),
        ),
        SliverToBoxAdapter(
          child: _footer(context, state, filter, result.length),
        ),
      ],
    ];
  }
}

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.value,
    required this.onChanged,
    this.favorites = false,
  });
  final ProductSort value;
  final ValueChanged<ProductSort> onChanged;
  final bool favorites;
  @override
  Widget build(BuildContext context) => PopupMenuButton<ProductSort>(
    tooltip: 'Ordenar productos',
    initialValue: value,
    onSelected: onChanged,
    itemBuilder: (_) =>
        (favorites
                ? [
                    ProductSort.recent,
                    ProductSort.cheapest,
                    ProductSort.expensive,
                    ProductSort.offers,
                  ]
                : [
                    ProductSort.recommended,
                    ProductSort.cheapest,
                    ProductSort.expensive,
                  ])
            .map(
              (sort) => PopupMenuItem(
                value: sort,
                child: Text(switch (sort) {
                  ProductSort.recommended => 'Recomendados',
                  ProductSort.cheapest => 'Menor precio',
                  ProductSort.expensive => 'Mayor precio',
                  ProductSort.recent => 'Más recientes',
                  ProductSort.offers => 'Ofertas',
                }),
              ),
            )
            .toList(),
    child: const Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(Icons.sort, size: 20),
          SizedBox(width: 5),
          Text('Ordenar'),
        ],
      ),
    ),
  );
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const LinearProgressIndicator(),
      const SizedBox(height: 18),
      Row(
        children: List.generate(
          2,
          (_) => Expanded(
            child: Container(
              height: 240,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onCatalog});
  final VoidCallback onCatalog;
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  ProductSort sort = ProductSort.recent;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    if (!state.signedIn) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'Guarda tus favoritos',
        message: 'Inicia sesión para guardar los productos que te gustan y verlos aquí.',
        action: 'Iniciar sesión',
        onAction: () => requireLogin(context, AuthPrompt.favorites),
      );
    }
    final filter = CatalogFilter()..sort = sort;
    final result = filter.apply(
      state.favoriteProducts,
      favorites: state.favorites,
    );
    if (result.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'Aún no tienes favoritos',
        message: 'Guarda los productos que más te gusten.',
        action: 'Explorar productos',
        onAction: widget.onCatalog,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tus favoritos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${result.length} productos guardados',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            SortMenu(
              value: sort,
              favorites: true,
              onChanged: (value) => setState(() => sort = value),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ProductGrid(
          products: result,
          favoriteActions: true,
          onOpen: (product) => openProduct(context, product),
        ),
      ],
    );
  }
}
