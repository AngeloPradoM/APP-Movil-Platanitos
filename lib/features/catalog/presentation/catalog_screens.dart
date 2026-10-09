import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../auth/presentation/auth_screens.dart';
import 'catalog_filters.dart';
import 'product_screen.dart';

export 'catalog_filters.dart';
export 'categories_screen.dart';
export 'category_screen.dart';
export 'home_screen.dart';

void openProduct(BuildContext context, Product product) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => ProductScreen(product: product)),
);

/// Listado general en una pantalla aparte con su propio filtro.
void openProductList(
  BuildContext context, {
  required String title,
  CatalogFilter? filter,
}) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => PageFrame(
      title: title,
      child: CatalogScreen(filter: filter ?? CatalogFilter()),
    ),
  ),
);

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.filter, this.header});

  /// Filtro propio; sin él usa el compartido con la portada y la búsqueda.
  final CatalogFilter? filter;
  final Widget? header;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  CatalogFilter _filterOf(ShopState state) => widget.filter ?? state.catalog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final state = ShopScope.of(context);
      await state.ensureCatalog();
      if (mounted && _filterOf(state).isActive) state.loadFullCatalog();
    });
  }

  /// Filtrar u ordenar necesita todo el catálogo; sin filtros se pagina.
  void _changed() {
    final state = ShopScope.of(context);
    if (widget.filter == null) return state.updateCatalog();
    setState(() {});
    if (widget.filter!.isActive) state.loadFullCatalog();
  }

  void _openFilters(FilterSection? section) {
    final state = ShopScope.of(context);
    state.loadFullCatalog();
    showFilterPanel(
      context,
      filter: _filterOf(state),
      source: (state) => state.catalogProducts,
      section: section,
      loading: (state) => state.catalogHasMore && !state.catalogMoreFailed,
      onApply: _changed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), filter = _filterOf(state);
    final source = state.catalogProducts;
    final result = filter.apply(source);
    return ColoredBox(
      color: AppColors.background,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.extentAfter < 600 &&
              !filter.isActive) {
            state.loadMoreCatalog();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            if (widget.header case final header?)
              SliverToBoxAdapter(child: header),
            PinnedHeaderSliver(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
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
                    ActiveFilterChips(filter: filter, onChanged: _changed),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              sliver: SliverMainAxisGroup(
                slivers: _results(context, state, filter, result),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final completing =
        filter.isActive && state.catalogHasMore && !state.catalogMoreFailed;
    final small = Theme.of(context).textTheme.bodySmall;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filter.query.isNotEmpty)
                      Text(
                        'Resultados para “${filter.query}”',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        filter.isActive
                            ? productsLabel(result.length)
                            : productsLabel(state.catalogTotal),
                        style: small,
                      ),
                    ),
                    if (completing)
                      Text('Buscando en todo el catálogo…', style: small),
                  ],
                ),
              ),
              if (filter.query.isNotEmpty)
                IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    filter.query = '';
                    _changed();
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
        ),
      ),
      if (state.catalogError != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OfflineBanner(onRetry: state.loadRemoteCatalog),
          ),
        ),
      if (state.catalogLoading || (result.isEmpty && completing))
        const SliverToBoxAdapter(child: CatalogSkeleton())
      else if (result.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No encontramos productos',
            message: 'Prueba con otra palabra o elimina los filtros.',
            action: 'Limpiar búsqueda y filtros',
            onAction: () {
              filter.clear();
              _changed();
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
                    ProductSort.discount,
                  ]
                : catalogSorts)
            .map((sort) => PopupMenuItem(value: sort, child: Text(sort.label)))
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
