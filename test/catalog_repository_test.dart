import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';

class _FakeClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final payload = {
      'data': [
        {
          'id': 'product-uuid',
          'name': 'Producto remoto',
          'slug': 'producto-remoto',
          'description': 'Descripción',
          'brand': {'name': 'Marca', 'slug': 'marca'},
          'category': {'name': 'Zapatillas', 'slug': 'zapatillas'},
          'images': [{'url': 'https://example.com/image.jpg'}],
          'variants': [
            {
              'id': 'variant-uuid',
              'sizeSystem': 'EUR',
              'sizeValue': '40',
              'color': 'Negro',
              'price': '199.90',
              'stock': 3,
            },
          ],
        },
      ],
      'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
    };
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(payload))),
      200,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  test('parsea el contrato remoto del catálogo', () async {
    final repository = CatalogRepository(client: ApiClient(baseUrl: 'http://test', client: _FakeClient()));
    final page = await repository.listProducts();

    expect(page.total, 1);
    expect(page.products.single.id, 'product-uuid');
    expect(page.products.single.variants.single.price, 199.90);
    expect(page.products.single.toShopProduct().remoteId, 'product-uuid');
  });
}
