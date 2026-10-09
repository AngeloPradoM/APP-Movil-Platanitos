import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import 'catalog_filters.dart';
import 'catalog_screens.dart' show openProduct;

Future<void> openCategory(
  BuildContext context, {
  required String title,
  required List<ShopCategory> categories,
}) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => CategoryScreen(title: title, categories: categories),
  ),
);

/// Productos de una o varias categorías con filtros propios que se
/// conservan al volver del detalle de un producto.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    super.key,
    required this.title,
    required this.categories,
  });
  final String title;
  final List<ShopCategory> categories;
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final filter = CatalogFilter();
  List<Product>? products;
  bool offline = false, failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final request = ++_request;
    final state = ShopScope.of(context);
    setState(() {
      failed = false;
      products = null;
    });
    try {
      final result = await state.loadCategoryProducts(widget.categories);
      if (!mounted || request != _request) return;
      setState(() {
        products = result.products;
        offline = result.offline;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => failed = true);
    }
  }

  void _changed() => setState(() {});

  void _openFilters(FilterSection? section) => showFilterPanel(
    context,
    filter: filter,
    source: (_) => products ?? const [],
    section: section,
    onApply: _changed,
  );

  void _selectSubcategory(ShopCategory? category) {
    filter.collection = category == null
        ? null
        : ProductCollection(category.name, category.contains);
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final source = products ?? const <Product>[];
    final result = filter.apply(source);
    final ready = products != null && !failed;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(ready, source, result)),
                  if (ready && source.isNotEmpty)
                    PinnedHeaderSliver(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CatalogFilterBar(
                              filter: filter,
                              facets: filter.facets(source),
                              onOpen: _openFilters,
                              onChanged: _changed,
                            ),
                            ActiveFilterChips(
                              filter: filter,
                              onChanged: _changed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    sliver: SliverMainAxisGroup(slivers: _results(result)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool ready, List<Product> source, List<Product> result) {
    final categories = widget.categories;
    final selected = filter.collection?.label;
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                !ready
                    ? (failed ? 'Sin resultados' : 'Cargando productos…')
                    : filter.narrows
                    ? '${productsLabel(result.length)} de ${source.length}'
                    : productsLabel(source.length),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (categories.length > 1 && ready) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in [null, ...categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterPill(
                          label: category?.name ?? 'Todas',
                          selected: category?.name == selected,
                          minHeight: 44,
                          onTap: () => _selectSubcategory(category),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _results(List<Product> result) {
    if (failed) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.cloud_off,
            title: 'No pudimos cargar esta categoría',
            message:
                'El sistema está fallando en este momento. Intenta más tarde.',
            action: 'Reintentar',
            onAction: _load,
          ),
        ),
      ];
    }
    if (products == null) {
      return const [SliverToBoxAdapter(child: CatalogSkeleton())];
    }
    return [
      if (offline)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: OfflineBanner(onRetry: _load),
          ),
        ),
      if (result.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off,
            title: products!.isEmpty
                ? 'Pronto tendremos productos aquí'
                : 'No hay productos con estos filtros',
            message: products!.isEmpty
                ? 'Mientras tanto, explora otras categorías.'
                : 'Prueba quitando algunos filtros.',
            action: filter.narrows ? 'Limpiar filtros' : null,
            onAction: () {
              filter
                ..clearSelections()
                ..collection = null;
              _changed();
            },
          ),
        )
      else
        ProductGrid.sliver(
          products: result,
          onOpen: (product) => openProduct(context, product),
        ),
    ];
  }
}
