import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/app_theme.dart';
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/features/catalog/presentation/catalog_screens.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';
import 'package:platanitos_app/widgets/shop_widgets.dart';

const _names = {
  'zapatillas-running': 'Zapatillas running',
  'polos': 'Polos',
  'mochilas': 'Mochilas',
  'equipaje': 'Equipaje',
};

Map<String, dynamic> _item(
  int index,
  String category, {
  required String brand,
  String color = 'Negro',
  double price = 100,
  double? comparePrice,
  String system = 'EUR',
  List<String> sizes = const ['38', '39', '40'],
}) => {
  'id': 'product-$index',
  'name': 'Producto $index',
  'slug': 'producto-$index',
  'description': null,
  'brand': {'name': brand, 'slug': brand.toLowerCase()},
  'category': {'name': _names[category], 'slug': category},
  'images': [
    {'url': 'https://example.com/$index.jpg'},
  ],
  'variants': [
    for (final size in sizes)
      {
        'id': 'variant-$index-$size',
        'sku': 'SKU-$index-$size',
        'sizeSystem': system,
        'sizeValue': size,
        'color': color,
        'price': price.toStringAsFixed(2),
        'comparePrice': comparePrice?.toStringAsFixed(2),
        'stock': 5,
      },
  ],
};

/// 60 zapatillas running (dos páginas), polos ALPHA y mochilas de talla única.
final _catalog = [
  for (var i = 0; i < 60; i++)
    _item(
      i,
      'zapatillas-running',
      brand: ['Nike', 'Adidas', 'Puma'][i % 3],
      color: i.isEven ? 'Negro' : 'Blanco',
      price: 90.0 + i * 5,
      comparePrice: i % 4 == 0 ? 400 : null,
    ),
  for (var i = 60; i < 66; i++)
    _item(i, 'polos', brand: 'Basement', system: 'ALPHA', sizes: ['S', 'M']),
  for (var i = 66; i < 69; i++)
    _item(i, 'mochilas', brand: 'Totto', system: 'ONE_SIZE', sizes: ['Única']),
];

class _Backend extends http.BaseClient {
  final requests = <Uri>[];
  bool offline = false;
  List<Map<String, dynamic>> items = _catalog;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url;
    requests.add(url);
    if (offline) return _json({'message': 'Error interno'}, 500);
    if (url.path == '/catalog/categories') {
      final counts = <String, int>{};
      for (final item in items) {
        final slug = (item['category'] as Map)['slug'] as String;
        counts.update(slug, (count) => count + 1, ifAbsent: () => 1);
      }
      return _json([
        for (final MapEntry(key: slug, value: count) in counts.entries)
          {
            'id': slug,
            'name': _names[slug],
            'slug': slug,
            'productCount': count,
            'image': 'https://example.com/$slug.jpg',
          },
        {
          'id': 'vacia',
          'name': 'Vacía',
          'slug': 'vacia',
          'productCount': 0,
          'image': null,
        },
      ]);
    }
    final query = url.queryParameters;
    final category = query['category'];
    final page = int.parse(query['page'] ?? '1');
    final limit = int.parse(query['limit'] ?? '20');
    final matching = [
      for (final item in items)
        if (category == null || (item['category'] as Map)['slug'] == category)
          item,
    ];
    return _json({
      'data': matching.skip((page - 1) * limit).take(limit).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': matching.length,
        'totalPages': (matching.length / limit).ceil(),
      },
    });
  }

  Iterable<String?> get categoryRequests => requests
      .where((url) => url.path == '/catalog/products')
      .map((url) => url.queryParameters['category']);

  http.StreamedResponse _json(Object payload, [int status = 200]) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(payload))),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

ShopState _state(_Backend backend) => ShopState(
  seedHistory: false,
  catalogRepository: CatalogRepository(
    client: ApiClient(baseUrl: 'http://test', client: backend),
  ),
);

const _running = ShopCategory(
  name: 'Zapatillas running',
  slug: 'zapatillas-running',
  productCount: 60,
);

Future<void> _mount(WidgetTester tester, ShopState state, Widget page) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ShopScope(
      state: state,
      child: MaterialApp(theme: buildTheme(), home: page),
    ),
  );
  await _settle(tester);
}

/// Desplaza solo la fila horizontal [row]; ensureVisible también movería la
/// lista vertical porque la barra está fija.
Future<void> _reveal(WidgetTester tester, Type row, String label) async {
  final scrollable = find.descendant(
    of: find.byType(row),
    matching: find.byType(Scrollable),
  );
  final target = find.descendant(
    of: scrollable,
    matching: find.text(label),
    skipOffstage: false,
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  await position.ensureVisible(
    tester.renderObject(target),
    alignment: 0.5,
  );
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('datos de categorías', () {
    test('el repositorio lee conteo e imagen y omite las vacías', () async {
      final backend = _Backend();
      final categories = await CatalogRepository(
        client: ApiClient(baseUrl: 'http://test', client: backend),
      ).listCategories();
      expect(categories.map((category) => category.slug), [
        'zapatillas-running',
        'polos',
        'mochilas',
      ]);
      expect(categories.first.productCount, 60);
      expect(categories.first.image, 'https://example.com/zapatillas-running.jpg');
    });

    test('carga todas las páginas de la categoría por slug', () async {
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);

      final result = await state.loadCategoryProducts([_running]);

      expect(result.offline, isFalse);
      expect(result.products, hasLength(60));
      expect(backend.categoryRequests, everyElement('zapatillas-running'));
      expect(
        backend.requests.map((url) => url.queryParameters['page']),
        ['1', '2'],
      );
    });

    test('los productos de una categoría se pueden marcar como favoritos', () async {
      final backend = _Backend();
      final state = _state(backend)..login();
      addTearDown(state.dispose);
      final product = (await state.loadCategoryProducts([_running]))
          .products
          .last;

      state.toggleFavorite(product.id);
      expect(state.favoriteProducts, contains(product));
    });

    test('sin conexión usa los productos de respaldo de esa categoría', () async {
      final backend = _Backend()..offline = true;
      final state = _state(backend);
      addTearDown(state.dispose);

      final result = await state.loadCategoryProducts([
        const ShopCategory(name: 'Botines', slug: 'botines', productCount: 1),
      ]);
      expect(result.offline, isTrue);
      expect(result.products.single.name, 'Botines Chelsea Abril');

      await expectLater(
        state.loadCategoryProducts([_running]),
        throwsA(isA<ApiException>()),
      );

      await state.loadCategories();
      expect(state.categoriesFailed, isTrue);
      expect(state.categories.map((category) => category.name), contains('Tacos'));
    });
  });

  group('pantalla de Categorías', () {
    testWidgets('muestra tarjetas con conteo y filtra por departamento', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const PageFrame(title: 'Categorías', child: CategoriesScreen()),
      );

      expect(find.bySemanticsLabel('Zapatillas running, 60 productos'), findsOneWidget);
      expect(find.bySemanticsLabel('Mochilas, 3 productos'), findsOneWidget);
      expect(find.text('Vacía'), findsNothing);
      expect(find.text('Hogar'), findsNothing, reason: 'departamento sin categorías');

      await tester.ensureVisible(find.text('Deportes'));
      await tester.tap(find.text('Deportes'));
      await tester.pump();
      expect(find.text('Zapatillas running'), findsOneWidget);
      expect(find.text('Polos'), findsNothing);

      await tester.tap(find.text('Zapatillas running'));
      await _settle(tester);
      expect(find.byType(CategoryScreen), findsOneWidget);
      expect(find.text('60 productos'), findsOneWidget);
      expect(backend.categoryRequests, contains('zapatillas-running'));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('si el backend falla muestra categorías de respaldo y Reintentar', (
      tester,
    ) async {
      final backend = _Backend()..offline = true;
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const PageFrame(title: 'Categorías', child: CategoriesScreen()),
      );

      expect(
        find.text(
          'El sistema está fallando en este momento. Mostramos categorías de respaldo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Botines'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);

      backend.offline = false;
      await tester.tap(find.text('Reintentar'));
      await _settle(tester);
      expect(find.text('Botines'), findsNothing);
      expect(find.text('Zapatillas running'), findsOneWidget);
    });

    testWidgets('el buscador muestra resultados de todo el catálogo', (
      tester,
    ) async {
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const PageFrame(title: 'Categorías', child: CategoriesScreen()),
      );

      await tester.enterText(find.byType(TextField), 'producto 6');
      await _settle(tester);
      expect(find.text('Resultados para “producto 6”'), findsOneWidget);
      expect(find.text('10 productos'), findsOneWidget);

      await tester.tap(find.text('Volver a categorías'));
      await tester.pump();
      expect(state.catalog.query, isEmpty);
      expect(find.text('Todas las categorías'), findsOneWidget);
    });
  });

  group('pantalla de una categoría', () {
    testWidgets('filtra por varias marcas desde el panel y quita chips', (
      tester,
    ) async {
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const CategoryScreen(title: 'Running', categories: [_running]),
      );
      expect(find.text('60 productos'), findsOneWidget);
      expect(find.text('Talla'), findsOneWidget);

      await _reveal(tester, CatalogFilterBar, 'Marca');
      await tester.tap(find.text('Marca'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Nike'));
      await tester.tap(find.text('Puma'));
      await tester.pump();
      await tester.tap(find.text('Ver 40 productos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('40 productos de 60'), findsOneWidget);
      expect(find.text('Marca (2)'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar filtro Nike'));
      await tester.pump();
      expect(find.text('20 productos de 60'), findsOneWidget);

      await _reveal(tester, CatalogFilterBar, 'Solo ofertas');
      await tester.tap(find.text('Solo ofertas'));
      await tester.pump();
      expect(find.text('5 productos de 60'), findsOneWidget);

      await _reveal(tester, ActiveFilterChips, 'Limpiar todo');
      await tester.tap(find.text('Limpiar todo'));
      await tester.pump();
      expect(find.text('60 productos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el panel completo combina precio y orden y cuenta resultados', (
      tester,
    ) async {
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const CategoryScreen(title: 'Running', categories: [_running]),
      );

      await tester.tap(find.text('Filtrar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (final title in ['Ordenar por', 'Precio', 'Talla', 'Marca', 'Color']) {
        expect(find.text(title), findsWidgets, reason: title);
      }
      expect(find.text('Calzado (EUR)'), findsNothing, reason: 'un solo sistema');
      await tester.tap(find.text('S/ 100 – 200 (20)'));
      await tester.tap(find.text('Mayor precio'));
      await tester.pump();
      await tester.tap(find.text('Ver 20 productos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('20 productos de 60'), findsOneWidget);
      expect(find.text('S/ 100 – 200'), findsWidgets);
      expect(find.text('Producto 22'), findsOneWidget, reason: 'S/ 200 primero');
    });

    testWidgets('categoría sin talla oculta el filtro y sin productos lo dice', (
      tester,
    ) async {
      final backend = _Backend();
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const CategoryScreen(
          title: 'Mochilas',
          categories: [
            ShopCategory(name: 'Mochilas', slug: 'mochilas', productCount: 3),
          ],
        ),
      );
      expect(find.text('3 productos'), findsOneWidget);
      expect(find.text('Talla'), findsNothing);

      backend.items = const [];
      await tester.pumpWidget(const SizedBox());
      await _mount(
        tester,
        state,
        const CategoryScreen(
          title: 'Mochilas',
          categories: [
            ShopCategory(name: 'Mochilas', slug: 'mochilas', productCount: 3),
          ],
        ),
      );
      expect(find.text('Pronto tendremos productos aquí'), findsOneWidget);
    });

    testWidgets('sin datos de respaldo muestra el error seguro y reintenta', (
      tester,
    ) async {
      final backend = _Backend()..offline = true;
      final state = _state(backend);
      addTearDown(state.dispose);
      await _mount(
        tester,
        state,
        const CategoryScreen(title: 'Running', categories: [_running]),
      );
      expect(find.text('No pudimos cargar esta categoría'), findsOneWidget);
      expect(
        find.text('El sistema está fallando en este momento. Intenta más tarde.'),
        findsOneWidget,
      );

      backend.offline = false;
      await tester.tap(find.text('Reintentar'));
      await _settle(tester);
      expect(find.text('60 productos'), findsOneWidget);
    });
  });

  testWidgets('el listado general vacío permite limpiar los filtros', (
    tester,
  ) async {
    final state = ShopState(seedHistory: false);
    addTearDown(state.dispose);
    await _mount(
      tester,
      state,
      PageFrame(
        title: 'Todos los productos',
        child: CatalogScreen(
          filter: CatalogFilter()
            ..brands.add('VIZZANO')
            ..colors.add('Blanco'),
        ),
      ),
    );
    expect(find.text('No encontramos productos'), findsOneWidget);
    await tester.tap(find.text('Limpiar búsqueda y filtros'));
    await tester.pump();
    expect(find.text('4 productos'), findsOneWidget);
  });
}
