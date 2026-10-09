import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

Product _product(
  int id, {
  String brand = 'Nike',
  String color = 'Negro',
  double price = 100,
  double? oldPrice,
  SizeSystem system = SizeSystem.eur,
  List<String> sizes = const ['38', '39'],
  List<int>? available,
  String category = 'Zapatillas running',
}) => Product(
  id: id,
  brand: brand,
  name: 'Producto $id',
  category: category,
  price: price,
  oldPrice: oldPrice ?? price,
  image: '',
  color: color,
  sizeSystem: system,
  sizes: sizes,
  availableSizes: available ?? List.generate(sizes.length, (index) => index),
);

ShopCategory _category(String name, [String? slug]) =>
    ShopCategory(name: name, slug: slug ?? slugify(name), productCount: 1);

void main() {
  group('agrupación de categorías', () {
    test('cada categoría cae en sus departamentos y el resto en Más', () {
      List<String> groups(String name) =>
          _category(name).groups.map((group) => group.label).toList();

      expect(groups('Zapatillas running'), ['Calzado', 'Deportes']);
      expect(groups('Botas y botines'), ['Calzado']);
      expect(groups('Conjuntos deportivos'), ['Ropa', 'Deportes']);
      expect(groups('Ropa de baño'), ['Ropa']);
      expect(groups('Carteras'), ['Bolsos']);
      expect(groups('Joyería y accesorios'), ['Accesorios']);
      expect(groups('Cocina y mesa'), ['Hogar']);
      expect(groups('Tecnología'), ['Tecnología']);
      expect(groups('Maquillaje'), ['Belleza']);
      expect(groups('Libros y cómics'), ['Juguetes y libros']);
      for (final name in ['Equipaje', 'Vinos y licores', 'Mascotas', 'Bebés']) {
        expect(groups(name), ['Más'], reason: name);
      }
      expect(CategoryGroup.all.includes(_category('Mascotas')), isTrue);
    });

    test('slugify coincide con los slugs del backend', () {
      expect(slugify('Ropa de baño'), 'ropa-de-bano');
      expect(slugify('Útiles y oficina'), 'utiles-y-oficina');
      expect(slugify('Libros y cómics'), 'libros-y-comics');
    });

    test('sin backend las categorías salen de los productos de respaldo', () {
      final categories = categoriesFromProducts(products);
      expect(categories.map((category) => category.name), [
        'Botines',
        'Sandalias',
        'Tacos',
        'Zapatillas',
      ]);
      expect(categories.first.productCount, 1);
      expect(categories.first.image, products[1].image);
      expect(categories.first.contains(products[1]), isTrue);
      expect(categories.first.contains(products[0]), isFalse);
    });
  });

  group('CatalogFilter', () {
    final source = [
      _product(1, brand: 'Nike', price: 80, oldPrice: 120),
      _product(2, brand: 'Adidas', color: 'Blanco', price: 150),
      _product(3, brand: 'Puma', price: 250, oldPrice: 300, available: [1]),
      _product(4, brand: 'Nike', color: 'Blanco', price: 320, available: []),
      _product(
        5,
        brand: 'Basement',
        system: SizeSystem.alpha,
        sizes: ['S', 'M', '4', '0-3M'],
        category: 'Polos',
        price: 100,
      ),
      _product(
        6,
        brand: 'Totto',
        system: SizeSystem.oneSize,
        sizes: ['Única'],
        category: 'Mochilas',
        price: 99,
      ),
    ];
    List<int> ids(CatalogFilter filter) =>
        filter.apply(source).map((product) => product.id).toList();

    test('selección múltiple: OR dentro de un filtro y AND entre filtros', () {
      final filter = CatalogFilter()..brands.addAll({'Nike', 'Puma'});
      expect(ids(filter), [1, 3, 4]);
      filter.colors.add('Blanco');
      expect(ids(filter), [4]);
      filter.colors.add('Negro');
      expect(ids(filter), [1, 3, 4]);
      expect(filter.selectionCount, 4);
    });

    test('la talla respeta el sistema y el stock de cada talla', () {
      final filter = CatalogFilter()
        ..sizes.add((system: SizeSystem.eur, value: '38'));
      expect(ids(filter), [1, 2]);
      filter.sizes
        ..clear()
        ..add((system: SizeSystem.alpha, value: 'M'));
      expect(ids(filter), [5]);
    });

    test('rangos de precio sin huecos ni solapes', () {
      final [upTo100, to200, to300, over300] = PriceRange.all;
      expect(upTo100.label, 'Hasta S/ 100');
      expect(to200.label, 'S/ 100 – 200');
      expect(over300.label, 'Más de S/ 300');
      expect(upTo100.contains(100), isTrue);
      expect(to200.contains(100), isFalse);
      expect(to200.contains(100.5), isTrue);
      expect(to300.contains(300), isTrue);
      expect(over300.contains(300.01), isTrue);

      final filter = CatalogFilter()..price = to300;
      expect(ids(filter), [3]);
      filter.price = upTo100;
      expect(ids(filter), [1, 5, 6]);
    });

    test('solo ofertas', () {
      final filter = CatalogFilter()..onSaleOnly = true;
      expect(ids(filter), [1, 3]);
    });

    test('ordenamientos', () {
      final filter = CatalogFilter();
      expect(ids(filter), [1, 2, 3, 5, 6, 4], reason: 'agotados al final');
      filter.sort = ProductSort.newest;
      expect(ids(filter), [1, 2, 3, 4, 5, 6]);
      filter.sort = ProductSort.cheapest;
      expect(ids(filter), [1, 6, 5, 2, 3, 4]);
      filter.sort = ProductSort.expensive;
      expect(ids(filter), [4, 3, 2, 5, 6, 1]);
      filter.sort = ProductSort.discount;
      expect(ids(filter).take(2), [1, 3]);
      expect(catalogSorts.map((sort) => sort.label), [
        'Recomendados',
        'Menor precio',
        'Mayor precio',
        'Mayor descuento',
        'Novedades',
      ]);
    });

    test('las facetas cuentan sin aplicar su propio filtro', () {
      final filter = CatalogFilter()..brands.add('Nike');
      final facets = filter.facets(source);
      expect(
        {for (final (:value, :count) in facets.brands) value: count},
        {'Adidas': 1, 'Basement': 1, 'Nike': 2, 'Puma': 1, 'Totto': 1},
      );
      expect(
        {for (final (:value, :count) in facets.colors) value: count},
        {'Blanco': 1, 'Negro': 1},
      );
      expect(facets.offers, 1);
      expect(facets.prices.map((option) => option.count), [1, 0, 0, 1]);
    });

    test('las tallas no mezclan sistemas y ocultan la talla única', () {
      final facets = CatalogFilter().facets(source);
      expect(
        facets.sizes.map((option) => sizeGroupLabel(option.value)).toSet(),
        {'Calzado (EUR)', 'Ropa', 'Ropa infantil', 'Bebés'},
      );
      expect(facets.sizes.map((option) => option.value.value), [
        '38',
        '39',
        'S',
        'M',
        '4',
        '0-3M',
      ]);
      expect(
        CatalogFilter().facets([source[5]]).sizes,
        isEmpty,
        reason: 'todo es talla única',
      );
    });

    test('copy es independiente y clearSelections conserva búsqueda y orden', () {
      final filter = CatalogFilter()
        ..query = 'zapatilla'
        ..sort = ProductSort.cheapest
        ..brands.add('Nike')
        ..onSaleOnly = true;
      final draft = filter.copy()..brands.add('Puma');
      expect(filter.brands, {'Nike'});
      filter.copyFrom(draft);
      expect(filter.brands, {'Nike', 'Puma'});
      filter.clearSelections();
      expect(filter.selectionCount, 0);
      expect(filter.query, 'zapatilla');
      expect(filter.sort, ProductSort.cheapest);
      expect(filter.narrows, isTrue);
      filter.clear();
      expect(filter.narrows, isFalse);
      expect(filter.isActive, isTrue);
    });
  });
}
