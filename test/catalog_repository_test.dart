import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

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

Map<String, dynamic> _variant(
  String size, {
  String system = 'EUR',
  int stock = 5,
  String price = '89.90',
  String? comparePrice,
}) => {
  'id': 'variant-$size',
  'sku': 'SKU-$size',
  'sizeSystem': system,
  'sizeValue': size,
  'color': 'Negro',
  'price': price,
  'comparePrice': comparePrice,
  'stock': stock,
};

Product _product(List<Map<String, dynamic>> variants) => CatalogProduct.fromJson({
  'id': 'product-uuid',
  'name': 'Producto',
  'slug': 'producto',
  'description': null,
  'brand': {'name': 'Marca', 'slug': 'marca'},
  'category': {'name': 'Categoría', 'slug': 'categoria'},
  'images': <Map<String, dynamic>>[],
  'variants': variants,
}).toShopProduct();

void main() {
  test('parsea el contrato remoto del catálogo', () async {
    final repository = CatalogRepository(client: ApiClient(baseUrl: 'http://test', client: _FakeClient()));
    final page = await repository.listProducts();

    expect(page.total, 1);
    expect(page.products.single.id, 'product-uuid');
    expect(page.products.single.variants.single.price, 199.90);
    expect(page.products.single.variants.single.comparePrice, isNull);
    expect(page.products.single.toShopProduct().remoteId, 'product-uuid');
  });

  test('traduce la talla remota a su índice con su stock', () async {
    final repository = CatalogRepository(client: ApiClient(baseUrl: 'http://test', client: _FakeClient()));
    final product = (await repository.listProducts()).products.single.toShopProduct();

    expect(product.sizes, ['40']);
    expect(product.availableSizes, [0]);
    expect(product.remoteVariantIds[0], 'variant-uuid');
    expect(product.variantStock[0], 3);
    expect(product.lowStock, isTrue);
  });

  test('ordena tallas EUR de cualquier rango y conserva el stock por talla', () {
    final product = _product([
      _variant('43'),
      _variant('38'),
      _variant('41', stock: 0),
      _variant('40', stock: 2),
    ]);

    expect(product.sizeSystem, SizeSystem.eur);
    expect(product.sizes, ['38', '40', '41', '43']);
    expect(product.availableSizes, [0, 1, 3]);
    expect(product.remoteVariantIds[2], 'variant-41');
    expect(product.variantStock, {0: 5, 1: 2, 2: 0, 3: 5});
    expect(product.convertible, isTrue);
    expect(product.sizeLabel(3, SizeSystem.us), '13');
    expect(product.sizeLabel(0, SizeSystem.cm), '24.5');

    final kids = _product([_variant('34'), _variant('27'), _variant('30')]);
    expect(kids.sizes, ['27', '30', '34']);
  });

  test('las tallas ALPHA se ordenan y no se convierten a US/CM', () {
    final product = _product([
      for (final size in ['XL', 'S', 'M', 'L'])
        _variant(size, system: 'ALPHA', stock: size == 'L' ? 0 : 4),
    ]);
    final cartItem = CartItem(
      product: product,
      sizeIndex: 1,
      system: SizeSystem.us,
    );

    expect(product.sizeSystem, SizeSystem.alpha);
    expect(product.sizes, ['S', 'M', 'L', 'XL']);
    expect(product.availableSizes, [0, 1, 3]);
    expect(product.convertible, isFalse);
    expect(product.sizeSystems, [SizeSystem.alpha]);
    expect(cartItem.size, 'M');

    final kids = _product([
      for (final size in ['12', '4', '8'])
        _variant(size, system: 'ALPHA'),
    ]);
    expect(kids.sizes, ['4', '8', '12']);
    final baby = _product([
      for (final size in ['12-18M', '0-3M', '6-12M'])
        _variant(size, system: 'ALPHA'),
    ]);
    expect(baby.sizes, ['0-3M', '6-12M', '12-18M']);
  });

  test('ONE_SIZE expone la talla Única y la bolsa la muestra como única', () {
    final product = _product([_variant('Única', system: 'ONE_SIZE')]);
    final state = ShopState(seedHistory: false);
    addTearDown(state.dispose);

    state.addToCart(product, 0, SizeSystem.eur);

    expect(product.sizeSystem, SizeSystem.oneSize);
    expect(product.sizes, ['Única']);
    expect(product.availableSizes, [0]);
    expect(state.cart.single.system, SizeSystem.oneSize);
    expect(state.cart.single.size, 'Única');
    expect(state.cart.single.sizeText, 'Talla única');
    expect(
      OrderItem.fromCart(state.cart.single).sizeText,
      'Talla única',
    );
  });

  test('comparePrice define el precio anterior y el descuento', () {
    final onSale = _product([
      for (final size in ['38', '39'])
        _variant(size, price: '89.90', comparePrice: '129.90'),
    ]);
    final regular = _product([_variant('38', price: '89.90')]);

    expect(onSale.price, 89.9);
    expect(onSale.oldPrice, 129.9);
    expect(onSale.onSale, isTrue);
    expect(onSale.discount, 31);
    expect(regular.oldPrice, regular.price);
    expect(regular.onSale, isFalse);
    expect(regular.discount, 0);
  });
}
