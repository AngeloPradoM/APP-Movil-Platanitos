part of '../../../../app/state/shop_state.dart';

extension CatalogController on ShopState {
  List<String> galleryOf(Product product) =>
      _galleries[product.slug] ?? product.gallery;

  Future<List<String>> loadGallery(Product product) async {
    final slug = product.slug, repository = catalogRepository;
    if (slug == null || repository == null) return galleryOf(product);
    final cached = _galleries[slug];
    if (cached != null) return cached;
    try {
      final images = (await repository.getProduct(slug)).images;
      if (images.isEmpty) return product.gallery;
      return _galleries[slug] = images;
    } catch (_) {
      return product.gallery;
    }
  }

  ({Product product, int sizeIndex})? _findRemoteVariant(String variantId) {
    for (final product in [
      ..._remoteProducts,
      for (final list in _categoryProducts.values) ...list,
      ..._favoriteProducts.values,
      ..._cartProducts.values,
    ]) {
      for (final entry in product.remoteVariantIds.entries) {
        if (entry.value == variantId) {
          return (product: product, sizeIndex: entry.key);
        }
      }
    }
    return null;
  }

  void updateCatalog() {
    _notifySafely();
    if (catalog.isActive) unawaited(loadFullCatalog());
  }

  /// Categorías del backend; si fallan se derivan de los productos cargados.
  List<ShopCategory> get categories =>
      _remoteCategories ?? categoriesFromProducts(catalogProducts);
  bool get categoriesLoading => _categoriesLoading;
  bool get categoriesFailed => _categoriesFailed;

  /// Hay backend pero aún no responde: se muestran marcadores de carga.
  bool get categoriesPending =>
      catalogRepository != null &&
      _remoteCategories == null &&
      !_categoriesFailed;

  Future<void> loadCategories() async {
    final repository = catalogRepository;
    if (repository == null || _categoriesLoading) return;
    _categoriesLoading = true;
    _categoriesFailed = false;
    _notifySafely();
    try {
      _remoteCategories = await repository.listCategories();
    } catch (_) {
      _categoriesFailed = true;
    } finally {
      _categoriesLoading = false;
      _notifySafely();
    }
  }

  /// Trae todas las páginas de cada categoría (son pocas) en vez del
  /// catálogo completo. Sin conexión usa lo ya cargado; si no hay nada
  /// que mostrar, propaga el error.
  Future<CategoryProducts> loadCategoryProducts(
    List<ShopCategory> selection,
  ) async {
    List<Product> local() => [
      for (final product in catalogProducts)
        if (selection.any((category) => category.contains(product))) product,
    ];
    final repository = catalogRepository;
    if (repository == null) return (products: local(), offline: false);
    try {
      final lists = await Future.wait(
        selection.map((category) => _fetchCategory(repository, category)),
      );
      final seen = <String?>{};
      return (
        products: [
          for (final list in lists)
            for (final product in list)
              if (seen.add(product.remoteId ?? product.slug)) product,
        ],
        offline: false,
      );
    } catch (_) {
      final cached = [
        for (final category in selection) ...?_categoryProducts[category.slug],
      ];
      final fallback = cached.isNotEmpty ? cached : local();
      if (fallback.isEmpty) rethrow;
      return (products: fallback, offline: true);
    }
  }

  Future<List<Product>> _fetchCategory(
    CatalogRepositoryContract repository,
    ShopCategory category,
  ) async {
    Future<CatalogPage> page(int number) => repository.listProducts(
      category: category.slug,
      page: number,
      limit: ShopState.catalogPageSize,
    );
    final first = await page(1);
    final rest = await Future.wait([
      for (var number = 2; number <= first.totalPages; number++) page(number),
    ]);
    return _categoryProducts[category.slug] = List.unmodifiable([
      for (final result in [first, ...rest])
        for (final product in result.products) product.toShopProduct(),
    ]);
  }

  /// Carga la primera página solo si aún no hay catálogo remoto.
  Future<void> ensureCatalog() =>
      _remoteProducts.isEmpty ? loadRemoteCatalog() : Future.value();

  /// Carga la primera página y reinicia la paginación del catálogo.
  Future<void> loadRemoteCatalog() async {
    if (catalogRepository == null || _catalogLoading) return;
    _catalogGeneration++;
    _catalogLoading = true;
    _catalogMoreFailed = false;
    _catalogError = null;
    _notifySafely();
    try {
      final page = await catalogRepository!.listProducts(
        limit: ShopState.catalogPageSize,
      );
      _remoteProducts = page.products
          .map((product) => product.toShopProduct())
          .toList(growable: false);
      _catalogPage = 1;
      _catalogTotal = page.total;
      _catalogTotalPages = page.totalPages;
    } catch (error) {
      _catalogError = error.toString();
      _remoteProducts = const [];
      _catalogPage = _catalogTotal = _catalogTotalPages = 0;
    } finally {
      _catalogLoading = false;
      _notifySafely();
    }
    if (catalog.isActive) unawaited(loadFullCatalog());
  }

  /// Agrega la siguiente página; si ya hay una en curso devuelve esa.
  Future<void> loadMoreCatalog() {
    if (catalogRepository == null || _catalogLoading || !catalogHasMore) {
      return Future.value();
    }
    return _catalogMoreRequest ??= _fetchNextCatalogPage().whenComplete(() {
      _catalogMoreRequest = null;
      _notifySafely();
    });
  }

  Future<void> _fetchNextCatalogPage() async {
    final generation = _catalogGeneration;
    final next = _catalogPage + 1;
    _catalogMoreFailed = false;
    _notifySafely();
    try {
      final page = await catalogRepository!.listProducts(
        page: next,
        limit: ShopState.catalogPageSize,
      );
      if (generation != _catalogGeneration) return;
      final loaded = {for (final product in _remoteProducts) product.remoteId};
      _remoteProducts = List.unmodifiable([
        ..._remoteProducts,
        for (final product in page.products)
          if (!loaded.contains(product.id)) product.toShopProduct(),
      ]);
      _catalogPage = next;
      _catalogTotal = page.total;
      _catalogTotalPages = page.totalPages;
    } catch (_) {
      if (generation == _catalogGeneration) _catalogMoreFailed = true;
    }
  }

  /// Trae las páginas restantes para que búsqueda, filtros y orden
  /// consideren todo el catálogo; se detiene si una página falla.
  Future<void> loadFullCatalog() => _fullCatalogRequest ??= () async {
    while (catalogHasMore &&
        !_catalogLoading &&
        !_catalogMoreFailed &&
        !_disposed) {
      await loadMoreCatalog();
    }
  }().whenComplete(() => _fullCatalogRequest = null);

  void retryCatalogPage() {
    _catalogMoreFailed = false;
    unawaited(catalog.isActive ? loadFullCatalog() : loadMoreCatalog());
  }
}
