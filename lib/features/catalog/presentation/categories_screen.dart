import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import 'catalog_filters.dart';
import 'catalog_screens.dart' show CatalogScreen, openProductList;
import 'category_screen.dart';

/// Pestaña "Categorías": departamentos y categorías con su conteo. Al buscar
/// (o al llegar desde la portada con un filtro) muestra el listado general.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  CategoryGroup group = CategoryGroup.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ShopScope.of(context);
      state.ensureCatalog();
      state.loadCategories();
    });
  }

  void _backToCategories(ShopState state) {
    FocusScope.of(context).unfocus();
    state.catalog
      ..clear()
      ..sort = ProductSort.recommended;
    state.updateCatalog();
  }

  void _retry(ShopState state) {
    state.loadCategories();
    state.ensureCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SearchField(
                value: state.catalog.query,
                onChanged: (value) {
                  state.catalog.query = value;
                  state.updateCatalog();
                },
                onSubmit: () => FocusScope.of(context).unfocus(),
              ),
            ),
          ),
          Expanded(
            child: state.catalog.narrows
                ? CatalogScreen(
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.darkGreen,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () => _backToCategories(state),
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Volver a categorías'),
                        ),
                      ),
                    ),
                  )
                : _browse(state),
          ),
        ],
      ),
    );
  }

  Widget _browse(ShopState state) {
    final categories = state.categories;
    final groups = [
      for (final group in CategoryGroup.values)
        if (group == CategoryGroup.all || categories.any(group.includes)) group,
    ];
    final current = groups.contains(group) ? group : CategoryGroup.all;
    final visible = categories.where(current.includes).toList();
    final loading = state.categoriesLoading;
    final small = Theme.of(context).textTheme.bodySmall;
    return CustomScrollView(
      key: const PageStorageKey('categories-browse'),
      slivers: [
        PinnedHeaderSliver(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Row(
                children: [
                  for (final item in groups)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPill(
                        label: item.label,
                        selected: item == current,
                        minHeight: 44,
                        onTap: () => setState(() => group = item),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (state.categoriesFailed)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: OfflineBanner(
                onRetry: () => _retry(state),
                message:
                    'El sistema está fallando en este momento. Mostramos categorías de respaldo.',
              ),
            ),
          ),
        SliverToBoxAdapter(child: _shortcuts(state)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Semantics(
                      header: true,
                      child: Text(
                        current == CategoryGroup.all
                            ? 'Todas las categorías'
                            : current.label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (visible.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      visible.length == 1
                          ? '1 categoría'
                          : '${visible.length} categorías',
                      style: small?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (state.categoriesPending)
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: _CategoryGrid(categories: [], skeleton: true),
          )
        else if (visible.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.cloud_off,
              title: 'No pudimos cargar las categorías',
              message:
                  'El sistema está fallando en este momento. Intenta más tarde.',
              action: 'Reintentar',
              onAction: () => _retry(state),
            ),
          )
        else ...[
          if (loading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _CategoryGrid(
              categories: visible,
              onOpen: (category) => openCategory(
                context,
                title: category.name,
                categories: [category],
              ),
            ),
          ),
          if (current != CategoryGroup.all && visible.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: OutlinedButton.icon(
                  style: outlineGreenButtonStyle,
                  onPressed: () => openCategory(
                    context,
                    title: current.label,
                    categories: visible,
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: Text('Ver todo en ${current.label}'),
                ),
              ),
            ),
        ],
        ..._brands(state),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }

  Widget _shortcuts(ShopState state) {
    final best = state.catalogProducts.fold(
      0,
      (top, product) => product.discount > top ? product.discount : top,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Shortcut(
                icon: Icons.grid_view_rounded,
                title: 'Ver todos los productos',
                subtitle: productsLabel(state.catalogTotal),
                onTap: () =>
                    openProductList(context, title: 'Todos los productos'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Shortcut(
                icon: Icons.local_offer_outlined,
                title: 'Ofertas',
                subtitle: best > 0 ? 'Hasta -$best%' : 'Descuentos de hoy',
                highlight: true,
                onTap: () => openProductList(
                  context,
                  title: 'Ofertas',
                  filter: CatalogFilter()
                    ..onSaleOnly = true
                    ..sort = ProductSort.discount,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marcas con más productos en lo cargado del catálogo.
  List<Widget> _brands(ShopState state) {
    final frequency = <String, int>{};
    for (final product in state.catalogProducts) {
      if (product.brand.isEmpty) continue;
      frequency.update(product.brand, (count) => count + 1, ifAbsent: () => 1);
    }
    final brands = frequency.keys.toList()
      ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));
    if (brands.isEmpty) return const [];
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
          child: Semantics(
            header: true,
            child: const Text(
              'Marcas destacadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56 + (scale - 1) * 20,
          child: ListView.separated(
            key: const PageStorageKey('category-brands'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: brands.take(12).length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Semantics(
                button: true,
                label: 'Ver productos de $brand',
                excludeSemantics: true,
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: InkWell(
                    onTap: () => openProductList(
                      context,
                      title: brand,
                      filter: CatalogFilter()..brands.add(brand),
                    ),
                    child: SizedBox(
                      width: 112 + (scale - 1) * 30,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              brand.toUpperCase(),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Material(
    color: highlight ? AppColors.darkGreen : Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: highlight ? AppColors.darkGreen : AppColors.border,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: highlight ? AppColors.yellow : AppColors.softGreen,
              child: Icon(
                icon,
                size: 19,
                color: highlight ? AppColors.ink : AppColors.darkGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: highlight ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: highlight ? AppColors.yellow : AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Grilla perezosa de tarjetas de categoría; con [skeleton] dibuja
/// marcadores mientras cargan.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    this.onOpen,
    this.skeleton = false,
  });
  final List<ShopCategory> categories;
  final ValueChanged<ShopCategory>? onOpen;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final width = constraints.crossAxisExtent;
        final count = (width / (110 * scale)).floor().clamp(2, 6);
        final itemWidth = (width - spacing * (count - 1)) / count;
        return SliverGrid.builder(
          itemCount: skeleton ? 6 : categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: itemWidth * .8 + 22 + 48 * scale,
          ),
          itemBuilder: (context, index) => skeleton
              ? Semantics(
                  label: index == 0 ? 'Cargando categorías' : null,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
              : _CategoryCard(
                  category: categories[index],
                  onOpen: () => onOpen?.call(categories[index]),
                ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onOpen});
  final ShopCategory category;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final image = category.image;
    return Semantics(
      button: true,
      label: '${category.name}, ${productsLabel(category.productCount)}',
      excludeSemantics: true,
      child: Material(
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
                      child: image == null
                          ? const Center(
                              child: Icon(
                                Icons.category_outlined,
                                color: AppColors.muted,
                                size: 32,
                              ),
                            )
                          : ShopImage(image, thumbnail: true),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  productsLabel(category.productCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
