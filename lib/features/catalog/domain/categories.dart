import '../../../shared/models/shop_models.dart';
import 'catalog_filter.dart';

class ShopCategory {
  const ShopCategory({
    required this.name,
    required this.slug,
    required this.productCount,
    this.image,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) => ShopCategory(
    name: json['name'] as String,
    slug: json['slug'] as String,
    productCount: json['productCount'] as int? ?? 0,
    image: json['image'] as String?,
  );

  final String name, slug;
  final int productCount;
  final String? image;

  bool contains(Product product) =>
      product.category == name || slugify(product.category) == slug;

  List<CategoryGroup> get groups => [
    for (final group in CategoryGroup.values)
      if (group != CategoryGroup.all && group.includes(this)) group,
  ];
}

String slugify(String value) => normalizeText(value)
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Departamentos de la tienda. Se calculan en la app a partir del nombre de
/// cada categoría para no cambiar el esquema; una categoría puede estar en
/// varios (p. ej. "Zapatillas running" en Calzado y Deportes) y las que no
/// coinciden con ninguno van a "Más".
enum CategoryGroup {
  all('Todo', []),
  shoes('Calzado', [
    'zapatilla',
    'sandalia',
    'bota',
    'botin',
    'calzado',
    'mocasin',
    'ballerina',
    'pantufla',
    'zueco',
    'taco',
  ]),
  clothing('Ropa', [
    'polo',
    'polera',
    'blusa',
    'casaca',
    'falda',
    'jean',
    'legging',
    'pantalon',
    'pijama',
    'ropa',
    'short',
    'vestido',
    'conjunto',
  ]),
  bags('Bolsos', ['bolso', 'cartera', 'mochila', 'morral']),
  accessories('Accesorios', [
    'accesorio',
    'billetera',
    'monedero',
    'correa',
    'cinturon',
    'joyer',
    'reloj',
    'lente',
  ]),
  sports('Deportes', ['deport', 'running', 'training', 'futbol', 'outdoor']),
  home('Hogar', ['hogar', 'cocina', 'decoracion', 'electrodomestico', 'mueble']),
  tech('Tecnología', ['tecnolog', 'electronic', 'audio', 'celular']),
  beauty('Belleza', ['belleza', 'maquillaje', 'cuidado', 'perfum']),
  toys('Juguetes y libros', ['juguete', 'juego', 'libro', 'comic']),
  more('Más', []);

  const CategoryGroup(this.label, this.words);
  final String label;
  final List<String> words;

  bool _matches(ShopCategory category) {
    final text = normalizeText('${category.name} ${category.slug}');
    return words.any(text.contains);
  }

  bool includes(ShopCategory category) => switch (this) {
    CategoryGroup.all => true,
    CategoryGroup.more => !values.any(
      (group) => group.words.isNotEmpty && group._matches(category),
    ),
    _ => _matches(category),
  };
}

/// Categorías de respaldo armadas con los productos disponibles en la app.
List<ShopCategory> categoriesFromProducts(Iterable<Product> products) {
  final byName = <String, List<Product>>{};
  for (final product in products) {
    if (product.category.isEmpty) continue;
    (byName[product.category] ??= []).add(product);
  }
  final names = byName.keys.toList()
    ..sort((a, b) => normalizeText(a).compareTo(normalizeText(b)));
  return [
    for (final name in names)
      ShopCategory(
        name: name,
        slug: slugify(name),
        productCount: byName[name]!.length,
        image: byName[name]!
            .map((product) => product.image)
            .where((image) => image.isNotEmpty)
            .firstOrNull,
      ),
  ];
}
