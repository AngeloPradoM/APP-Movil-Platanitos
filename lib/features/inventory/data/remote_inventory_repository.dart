import '../../../core/network/access_token_store.dart';
import '../../../core/network/api_client.dart';
import '../domain/inventory_models.dart';
import '../domain/repositories/inventory_repository.dart';

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.productCount,
    required this.isActive,
  });
  final String id;
  final String name;
  final String slug;
  final int productCount;
  final bool isActive;
}

class RemoteInventoryRepository implements InventoryRepository {
  RemoteInventoryRepository(this._client, this._tokens);
  final ApiClient _client;
  final AccessTokenStore _tokens;

  String get _token {
    final token = _tokens.value;
    if (token == null || token.isEmpty) {
      throw StateError('Inicia sesión para ver el inventario.');
    }
    return token;
  }

  @override
  Future<List<InventoryItem>> list({
    String query = '',
    bool lowStockOnly = false,
  }) async {
    final payload = await _client.get(
      '/inventory?q=${Uri.encodeQueryComponent(query)}&lowStock=${lowStockOnly ? '1' : '0'}',
      accessToken: _token,
    );
    return [
      for (final raw in payload as List<dynamic>)
        InventoryItem(
          variantId: (raw as Map)['variantId'] as String,
          productId: raw['productId'] as String,
          productName: raw['productName'] as String,
          category: raw['category'] as String? ?? '',
          price: double.parse('${raw['price']}'),
          sizeSystem: raw['sizeSystem'] as String,
          sizeValue: raw['sizeValue'] as String,
          color: raw['color'] as String,
          physicalStock: raw['physicalStock'] as int,
          reservedStock: raw['reservedStock'] as int,
        ),
    ];
  }

  @override
  Future<List<StockMovement>> movements({
    String? variantId,
    int limit = 50,
  }) async {
    if (variantId == null) return const [];
    final payload = await _client.get(
      '/inventory/${Uri.encodeComponent(variantId)}/movements',
      accessToken: _token,
    );
    return [
      for (final raw in (payload as List<dynamic>).take(limit))
        StockMovement(
          id: (raw as Map)['id'] as int,
          variantId: raw['variantId'] as String,
          type: StockMovementType.values.byName(raw['type'] as String),
          quantity: raw['quantity'] as int,
          reason: raw['reason'] as String? ?? '',
          responsibleUserId: raw['responsibleUserId'] as String? ?? '',
          createdAt: DateTime.parse(raw['createdAt'] as String).toLocal(),
        ),
    ];
  }

  @override
  Future<void> registerMovement({
    required String variantId,
    required StockMovementType type,
    required int quantity,
    required String reason,
    required String responsibleUserId,
  }) async {
    await _client.post(
      '/inventory/${Uri.encodeComponent(variantId)}/movements',
      accessToken: _token,
      body: {'type': type.name, 'quantity': quantity, 'reason': reason},
    );
  }

  @override
  Future<void> updatePrice({
    required String variantId,
    required double price,
  }) async {
    await _client.patch(
      '/inventory/${Uri.encodeComponent(variantId)}/price',
      accessToken: _token,
      body: {'price': price},
    );
  }

  Future<List<InventoryCategory>> categories() async {
    final payload = await _client.get(
      '/inventory/categories',
      accessToken: _token,
    );
    return [
      for (final raw in payload as List<dynamic>)
        InventoryCategory(
          id: (raw as Map)['id'] as String,
          name: raw['name'] as String,
          slug: raw['slug'] as String,
          productCount: raw['productCount'] as int? ?? 0,
          isActive: raw['isActive'] as bool? ?? true,
        ),
    ];
  }

  Future<void> setCategoryActive(String id, bool isActive) async {
    await _client.patch(
      '/inventory/categories/${Uri.encodeComponent(id)}',
      accessToken: _token,
      body: {'isActive': isActive},
    );
  }

  Future<List<CatalogBrand>> brands() async {
    final payload = await _client.get('/inventory/brands', accessToken: _token);
    return [
      for (final raw in payload as List<dynamic>)
        CatalogBrand(
          id: (raw as Map)['id'] as String,
          name: raw['name'] as String,
        ),
    ];
  }

  Future<EditableProduct> product(String productId) async {
    final raw = Map<String, dynamic>.from(
      await _client.get(
            '/inventory/products/${Uri.encodeComponent(productId)}',
            accessToken: _token,
          )
          as Map,
    );
    return EditableProduct.fromJson(raw);
  }

  Future<EditableProduct> saveProduct(EditableProduct product) async {
    final body = product.toJson();
    final raw = product.id == null
        ? await _client.post(
            '/inventory/products',
            accessToken: _token,
            body: body,
          )
        : await _client.put(
            '/inventory/products/${Uri.encodeComponent(product.id!)}',
            accessToken: _token,
            body: body,
          );
    return EditableProduct.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}

class CatalogBrand {
  const CatalogBrand({required this.id, required this.name});
  final String id;
  final String name;
}

class EditableImage {
  EditableImage({required this.url, this.altText = ''});
  String url;
  String altText;
  Map<String, dynamic> toJson() => {'url': url, 'altText': altText};
}

class EditableVariant {
  EditableVariant({
    this.id,
    this.sizeSystem = 'EUR',
    this.sizeValue = '',
    this.color = '',
    this.price = '',
    this.stock = '0',
  });
  String? id;
  String sizeSystem;
  String sizeValue;
  String color;
  String price;
  String stock;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'sizeSystem': sizeSystem,
    'sizeValue': sizeValue,
    'color': color,
    'price': double.parse(price.replaceAll(',', '.')),
    'stock': int.parse(stock),
  };
}

class EditableProduct {
  EditableProduct({
    this.id,
    this.name = '',
    this.description = '',
    this.categoryId = '',
    this.brandId = '',
    List<EditableImage>? images,
    List<EditableVariant>? variants,
  }) : images = images ?? [EditableImage(url: '')],
       variants = variants ?? [EditableVariant()];

  factory EditableProduct.fromJson(Map<String, dynamic> json) =>
      EditableProduct(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        brandId: json['brandId'] as String? ?? '',
        images: [
          for (final raw in json['images'] as List<dynamic>? ?? const [])
            EditableImage(
              url: (raw as Map)['url'] as String? ?? '',
              altText: raw['altText'] as String? ?? '',
            ),
        ],
        variants: [
          for (final raw in json['variants'] as List<dynamic>? ?? const [])
            EditableVariant(
              id: (raw as Map)['id'] as String?,
              sizeSystem: raw['sizeSystem'] as String? ?? 'EUR',
              sizeValue: raw['sizeValue'] as String? ?? '',
              color: raw['color'] as String? ?? '',
              price: '${raw['price']}',
              stock: '${raw['stock']}',
            ),
        ],
      );

  final String? id;
  String name;
  String description;
  String categoryId;
  String brandId;
  final List<EditableImage> images;
  final List<EditableVariant> variants;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'brandId': brandId,
    'images': [
      for (final image in images)
        if (image.url.trim().isNotEmpty) image.toJson(),
    ],
    'variants': [for (final variant in variants) variant.toJson()],
  };
}
