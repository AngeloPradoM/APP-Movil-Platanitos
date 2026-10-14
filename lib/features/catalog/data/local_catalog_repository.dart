import '../../../core/database/app_database.dart';
import 'catalog_repository.dart';
import '../domain/categories.dart';

class LocalCatalogRepository implements CatalogRepositoryContract {
  LocalCatalogRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<CatalogPage> listProducts({
    String? query,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final all = await _loadProducts();
    final normalizedQuery = query?.trim().toLowerCase() ?? '';
    final filtered = all
        .where((product) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              '${product.brand} ${product.name} ${product.category}'
                  .toLowerCase()
                  .contains(normalizedQuery);
          final matchesCategory =
              category == null ||
              category.isEmpty ||
              slugify(product.category) == category;
          return matchesQuery && matchesCategory;
        })
        .toList(growable: false);
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 20 : limit;
    final start = (safePage - 1) * safeLimit;
    final end = (start + safeLimit).clamp(0, filtered.length);
    final values = start >= filtered.length
        ? <CatalogProduct>[]
        : filtered.sublist(start, end);
    return CatalogPage(
      products: values,
      page: safePage,
      total: filtered.length,
      totalPages: filtered.isEmpty ? 0 : (filtered.length / safeLimit).ceil(),
    );
  }

  @override
  Future<List<ShopCategory>> listCategories() async {
    final page = await listProducts(limit: 1000);
    return categoriesFromProducts(
      page.products.map((item) => item.toShopProduct()),
    );
  }

  @override
  Future<CatalogProduct> getProduct(String slug) async {
    final products = await _loadProducts(
      where: 'p.slug = ?',
      whereArgs: [slug],
    );
    if (products.isEmpty) throw StateError('Producto no encontrado.');
    return products.first;
  }

  Future<List<CatalogProduct>> _loadProducts({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final productRows = await _appDatabase.database.rawQuery('''
      SELECT p.* FROM products p
      WHERE p.active = 1 ${where == null ? '' : 'AND $where'}
      ORDER BY p.local_id
    ''', whereArgs);
    final result = <CatalogProduct>[];
    for (final row in productRows) {
      final variants = await _appDatabase.database.query(
        'product_variants',
        where: 'product_id = ?',
        whereArgs: [row['id']],
        orderBy: 'CAST(size_value AS INTEGER), color',
      );
      result.add(
        CatalogProduct(
          id: row['id'] as String,
          name: row['name'] as String,
          slug: row['slug'] as String,
          description: row['description'] as String?,
          brand: row['brand'] as String,
          category: row['category'] as String,
          images: [row['image'] as String],
          variants: variants
              .map(
                (variant) => CatalogVariant(
                  id: variant['id'] as String,
                  sizeSystem: variant['size_system'] as String,
                  sizeValue: variant['size_value'] as String,
                  color: variant['color'] as String,
                  price: (row['price_cents'] as int) / 100,
                  comparePrice:
                      (row['compare_price_cents'] as int?)?.toDouble() == null
                      ? null
                      : (row['compare_price_cents'] as int) / 100,
                  stock:
                      (variant['physical_stock'] as int) -
                      (variant['reserved_stock'] as int),
                ),
              )
              .toList(growable: false),
        ),
      );
    }
    return result;
  }
}
