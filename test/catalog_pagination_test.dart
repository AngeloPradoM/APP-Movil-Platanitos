import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

class _PagedBackend extends http.BaseClient {
  _PagedBackend(int count)
    : items = [
        for (var i = 1; i <= count; i++)
          {
            'id': 'product-$i',
            'name': 'Producto $i',
            'slug': 'producto-$i',
            'description': null,
            'brand': {'name': 'Marca', 'slug': 'marca'},
            'category': {'name': 'Zapatillas', 'slug': 'zapatillas'},
            'images': <Map<String, dynamic>>[],
            'variants': [
              {
                'id': 'variant-$i',
                'sizeSystem': 'EUR',
                'sizeValue': '38',
                'color': 'Negro',
                'price': '99.90',
                'comparePrice': null,
                'stock': 5,
              },
            ],
          },
      ];
  final List<Map<String, dynamic>> items;
  final requestedPages = <int>[];
  int? failPage;
  bool offline = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final query = request.url.queryParameters;
    final page = int.parse(query['page'] ?? '1');
    final limit = int.parse(query['limit'] ?? '20');
    requestedPages.add(page);
    if (offline || page == failPage) {
      return _json({'message': 'Error interno'}, 500);
    }
    return _json({
      'data': items.skip((page - 1) * limit).take(limit).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': items.length,
        'totalPages': (items.length / limit).ceil(),
      },
    });
  }

  http.StreamedResponse _json(Object payload, [int status = 200]) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(payload))),
        status,
        headers: {'content-type': 'application/json'},
      );
}

ShopState _buildState(_PagedBackend backend) => ShopState(
  seedHistory: false,
  catalogRepository: CatalogRepository(
    client: ApiClient(baseUrl: 'http://test', client: backend),
  ),
);

Future<void> _settle() async {
  for (var i = 0; i < 40; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('carga páginas de 50 hasta completar el catálogo', () async {
    final backend = _PagedBackend(120);
    final state = _buildState(backend);
    addTearDown(state.dispose);

    await state.loadRemoteCatalog();
    expect(state.catalogProducts, hasLength(50));
    expect(state.catalogTotal, 120);
    expect(state.catalogHasMore, isTrue);

    await Future.wait([state.loadMoreCatalog(), state.loadMoreCatalog()]);
    expect(state.catalogProducts, hasLength(100));

    await state.loadMoreCatalog();
    expect(state.catalogProducts, hasLength(120));
    expect(state.catalogHasMore, isFalse);
    expect(state.catalogProducts.last.name, 'Producto 120');
    expect(backend.requestedPages, [1, 2, 3]);
  });

  test('la búsqueda trae el resto de páginas para filtrar todo el catálogo', () async {
    final backend = _PagedBackend(120);
    final state = _buildState(backend);
    addTearDown(state.dispose);
    await state.loadRemoteCatalog();

    state.catalog.query = 'Producto 119';
    state.updateCatalog();
    await state.loadFullCatalog();

    expect(state.catalogProducts, hasLength(120));
    expect(state.catalog.apply(state.catalogProducts).single.name, 'Producto 119');
    expect(backend.requestedPages, [1, 2, 3]);
  });

  test('si falla una página conserva lo cargado y permite reintentar', () async {
    final backend = _PagedBackend(120)..failPage = 2;
    final state = _buildState(backend);
    addTearDown(state.dispose);
    await state.loadRemoteCatalog();

    await state.loadMoreCatalog();
    expect(state.catalogMoreFailed, isTrue);
    expect(state.catalogProducts, hasLength(50));
    expect(state.catalogError, isNull);

    backend.failPage = null;
    state.retryCatalogPage();
    await _settle();
    expect(state.catalogMoreFailed, isFalse);
    expect(state.catalogProducts, hasLength(100));
  });

  test('sin backend se mantienen los productos de respaldo', () async {
    final backend = _PagedBackend(120)..offline = true;
    final state = _buildState(backend);
    addTearDown(state.dispose);

    await state.loadRemoteCatalog();

    expect(state.catalogError, isNotNull);
    expect(state.catalogProducts, products);
    expect(state.catalogHasMore, isFalse);
    await state.loadMoreCatalog();
    expect(backend.requestedPages, [1]);
  });
}
