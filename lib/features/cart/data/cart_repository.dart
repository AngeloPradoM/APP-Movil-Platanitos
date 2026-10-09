import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';

class RemoteCartItem {
  const RemoteCartItem({
    required this.id,
    required this.quantity,
    required this.variantId,
    required this.sizeSystem,
    required this.sizeValue,
    required this.color,
    required this.price,
    required this.stock,
    required this.productName,
    required this.productSlug,
  });
  factory RemoteCartItem.fromJson(Map<String, dynamic> json) {
    final variant = Map<String, dynamic>.from(json['variant'] as Map);
    final product = Map<String, dynamic>.from(variant['product'] as Map);
    return RemoteCartItem(
      id: json['id'] as String,
      quantity: json['quantity'] as int,
      variantId: variant['id'] as String,
      sizeSystem: variant['sizeSystem'] as String,
      sizeValue: variant['sizeValue'] as String,
      color: variant['color'] as String,
      price: double.parse(variant['price'] as String),
      stock: variant['stock'] as int,
      productName: product['name'] as String,
      productSlug: product['slug'] as String,
    );
  }
  final String id, variantId, sizeSystem, sizeValue, color;
  final String productName, productSlug;
  final int quantity, stock;
  final double price;
}

class RemoteCart {
  const RemoteCart({required this.items, required this.itemCount});
  factory RemoteCart.fromJson(Map<String, dynamic> json) => RemoteCart(
    items: (json['items'] as List<dynamic>)
        .map(
          (item) =>
              RemoteCartItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
    itemCount: json['itemCount'] as int,
  );
  final List<RemoteCartItem> items;
  final int itemCount;
}

class CartRepository {
  CartRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  Future<RemoteCart> getCart({required String accessToken}) async =>
      _parse(await _client.get('/cart', accessToken: accessToken));

  Future<RemoteCart> addItem({
    required String accessToken,
    required String variantId,
    int quantity = 1,
  }) async => _parse(
    await _client.post(
      '/cart/items',
      accessToken: accessToken,
      body: {'variantId': variantId, 'quantity': quantity},
    ),
  );

  Future<RemoteCart> sync({
    required String accessToken,
    required List<Map<String, dynamic>> items,
  }) async => _parse(
    await _client.post(
      '/cart/sync',
      accessToken: accessToken,
      body: {'items': items},
    ),
  );

  Future<RemoteCart> updateItem({
    required String accessToken,
    required String itemId,
    required int quantity,
  }) async => _parse(
    await _client.patch(
      '/cart/items/${Uri.encodeComponent(itemId)}',
      accessToken: accessToken,
      body: {'quantity': quantity},
    ),
  );

  Future<RemoteCart> removeItem({
    required String accessToken,
    required String itemId,
  }) async => _parse(
    await _client.delete(
      '/cart/items/${Uri.encodeComponent(itemId)}',
      accessToken: accessToken,
    ),
  );

  RemoteCart _parse(dynamic payload) =>
      RemoteCart.fromJson(Map<String, dynamic>.from(payload as Map));
}
