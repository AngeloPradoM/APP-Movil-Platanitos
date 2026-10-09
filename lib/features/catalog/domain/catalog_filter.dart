import '../../../shared/models/shop_models.dart';

enum ProductSort { recommended, cheapest, expensive, discount, newest, recent }

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
    ProductSort.recommended => 'Recomendados',
    ProductSort.cheapest => 'Menor precio',
    ProductSort.expensive => 'Mayor precio',
    ProductSort.discount => 'Mayor descuento',
    ProductSort.newest => 'Novedades',
    ProductSort.recent => 'Más recientes',
  };
}

/// Ordenamientos del listado de la tienda (favoritos usa los suyos).
const catalogSorts = [
  ProductSort.recommended,
  ProductSort.cheapest,
  ProductSort.expensive,
  ProductSort.discount,
  ProductSort.newest,
];

/// Grupo de productos que se abre desde la portada (categoría, público, ofertas…).
class ProductCollection {
  const ProductCollection(this.label, this.matches, {this.categoryWords});

  /// Colección definida por palabras del nombre de la categoría; así la
  /// portada puede abrir directamente las categorías que le corresponden.
  factory ProductCollection.categories(String label, List<String> words) =>
      ProductCollection(label, (product) {
        final category = normalizeText(product.category);
        return words.any((word) => category.contains(normalizeText(word)));
      }, categoryWords: words);

  final String label;
  final bool Function(Product product) matches;
  final List<String>? categoryWords;
}

/// Rango de precio: excluye el mínimo (salvo el primero) e incluye el máximo.
class PriceRange {
  const PriceRange(this.min, this.max);
  final double min, max;

  static const all = [
    PriceRange(0, 100),
    PriceRange(100, 200),
    PriceRange(200, 300),
    PriceRange(300, double.infinity),
  ];

  bool contains(double price) => (price > min || min == 0) && price <= max;

  String get label {
    String amount(double value) => 'S/ ${value.toStringAsFixed(0)}';
    if (min == 0) return 'Hasta ${amount(max)}';
    if (!max.isFinite) return 'Más de ${amount(min)}';
    return '${amount(min)} – ${max.toStringAsFixed(0)}';
  }

  @override
  bool operator ==(Object other) =>
      other is PriceRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}

typedef SizeOption = ({SizeSystem system, String value});

/// Sección del filtro de talla: no se mezclan calzado, ropa y bebés.
String sizeGroupLabel(SizeOption size) {
  if (size.system != SizeSystem.alpha) return 'Calzado (${size.system.label})';
  final value = size.value.toUpperCase();
  if (value.endsWith('M') && value.contains(RegExp(r'\d'))) return 'Bebés';
  return int.tryParse(value) != null ? 'Ropa infantil' : 'Ropa';
}

int compareSizeOptions(SizeOption a, SizeOption b) {
  const groups = ['Ropa', 'Ropa infantil', 'Bebés'];
  int group(SizeOption size) => groups.indexOf(sizeGroupLabel(size)) + 1;
  final byGroup = group(a).compareTo(group(b));
  return byGroup != 0 ? byGroup : compareSizes(a.value, b.value);
}

enum FilterFacet { size, brand, color, price, offers }

typedef FacetCount<T> = ({T value, int count});

/// Opciones disponibles para cada filtro con cuántos productos quedarían.
/// Cada conteo considera los demás filtros activos, no el propio.
class CatalogFacets {
  const CatalogFacets({
    required this.sizes,
    required this.brands,
    required this.colors,
    required this.prices,
    required this.offers,
  });
  final List<FacetCount<SizeOption>> sizes;
  final List<FacetCount<String>> brands, colors;
  final List<FacetCount<PriceRange>> prices;
  final int offers;
}

String normalizeText(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  return value
      .toLowerCase()
      .split('')
      .map((char) => accents[char] ?? char)
      .join();
}

class CatalogFilter {
  String query = '';
  ProductCollection? collection;
  final brands = <String>{}, colors = <String>{};
  final sizes = <SizeOption>{};
  PriceRange? price;
  bool onSaleOnly = false;
  ProductSort sort = ProductSort.recommended;

  int get selectionCount =>
      brands.length +
      colors.length +
      sizes.length +
      (price == null ? 0 : 1) +
      (onSaleOnly ? 1 : 0);

  /// Búsqueda o filtros que reducen el resultado (el orden no cuenta).
  bool get narrows =>
      query.trim().isNotEmpty || collection != null || selectionCount > 0;

  /// Búsqueda, filtros u orden que deben considerar todo el catálogo.
  bool get isActive => narrows || sort != ProductSort.recommended;

  bool matches(Product product, {FilterFacet? except}) {
    final term = normalizeText(query.trim());
    return (term.isEmpty ||
            normalizeText(
              '${product.name} ${product.brand} ${product.category}',
            ).contains(term)) &&
        (collection?.matches(product) ?? true) &&
        (except == FilterFacet.brand ||
            brands.isEmpty ||
            brands.contains(product.brand)) &&
        (except == FilterFacet.color ||
            colors.isEmpty ||
            colors.contains(product.color)) &&
        (except == FilterFacet.price ||
            price == null ||
            price!.contains(product.price)) &&
        (except == FilterFacet.offers || !onSaleOnly || product.onSale) &&
        (except == FilterFacet.size ||
            sizes.isEmpty ||
            _sizesOf(product).any(sizes.contains));
  }

  static Iterable<SizeOption> _sizesOf(Product product) =>
      product.sizeSystem == SizeSystem.oneSize
      ? const []
      : {
          for (final index in product.availableSizes)
            if (index < product.sizes.length)
              (system: product.sizeSystem, value: product.sizes[index]),
        };

  /// "Recomendados" pone primero lo que tiene stock y conserva el orden de
  /// origen; "Novedades" respeta el orden del backend (más recientes primero).
  List<Product> apply(Iterable<Product> source, {List<int>? favorites}) {
    final result = source.where(matches).toList();
    if (sort == ProductSort.newest) return result;
    final position = {
      for (final (index, product) in result.indexed) product: index,
    };
    result.sort((a, b) {
      final order = switch (sort) {
        ProductSort.cheapest => a.price.compareTo(b.price),
        ProductSort.expensive => b.price.compareTo(a.price),
        ProductSort.discount => b.discount.compareTo(a.discount),
        ProductSort.recent => (favorites?.indexOf(b.id) ?? b.id).compareTo(
          favorites?.indexOf(a.id) ?? a.id,
        ),
        ProductSort.recommended => (a.availableSizes.isEmpty ? 1 : 0)
            .compareTo(b.availableSizes.isEmpty ? 1 : 0),
        ProductSort.newest => 0,
      };
      return order != 0 ? order : position[a]!.compareTo(position[b]!);
    });
    return result;
  }

  CatalogFacets facets(Iterable<Product> source) {
    final products = source.toList(growable: false);
    Map<T, int> count<T>(FilterFacet facet, Iterable<T> Function(Product) of) {
      final counts = <T, int>{};
      for (final product in products) {
        if (!matches(product, except: facet)) continue;
        for (final value in of(product).toSet()) {
          counts.update(value, (total) => total + 1, ifAbsent: () => 1);
        }
      }
      return counts;
    }

    List<FacetCount<T>> options<T>(
      Map<T, int> counts,
      Set<T> selected,
      int Function(T, T) compare,
    ) {
      final values = {...counts.keys, ...selected}.toList()..sort(compare);
      return [for (final value in values) (value: value, count: counts[value] ?? 0)];
    }

    final sizeCounts = count(FilterFacet.size, _sizesOf);
    final brandCounts = count(FilterFacet.brand, (p) => [
      if (p.brand.isNotEmpty) p.brand,
    ]);
    final colorCounts = count(FilterFacet.color, (p) => [
      if (p.color.isNotEmpty) p.color,
    ]);
    final priceCounts = count(
      FilterFacet.price,
      (p) => PriceRange.all.where((range) => range.contains(p.price)),
    );
    int byName(String a, String b) =>
        normalizeText(a).compareTo(normalizeText(b));
    return CatalogFacets(
      sizes: options(sizeCounts, sizes, compareSizeOptions),
      brands: options(brandCounts, brands, byName),
      colors: options(colorCounts, colors, byName),
      prices: [
        for (final range in PriceRange.all)
          (value: range, count: priceCounts[range] ?? 0),
      ],
      offers: products
          .where((p) => p.onSale && matches(p, except: FilterFacet.offers))
          .length,
    );
  }

  CatalogFilter copy() => CatalogFilter()..copyFrom(this);

  void copyFrom(CatalogFilter other) {
    query = other.query;
    collection = other.collection;
    brands
      ..clear()
      ..addAll(other.brands);
    colors
      ..clear()
      ..addAll(other.colors);
    sizes
      ..clear()
      ..addAll(other.sizes);
    price = other.price;
    onSaleOnly = other.onSaleOnly;
    sort = other.sort;
  }

  /// Quita los filtros del panel; conserva búsqueda, colección y orden.
  void clearSelections() {
    brands.clear();
    colors.clear();
    sizes.clear();
    price = null;
    onSaleOnly = false;
  }

  void clear() {
    clearSelections();
    collection = null;
    query = '';
  }
}
