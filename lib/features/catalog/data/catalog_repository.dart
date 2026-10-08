import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/shop_models.dart';

class CatalogVariant {
  const CatalogVariant({
    required this.id,
    required this.sizeSystem,
    required this.sizeValue,
    required this.color,
    required this.price,
    required this.stock,
  });
  factory CatalogVariant.fromJson(Map<String, dynamic> json) => CatalogVariant(
    id: json['id'] as String,
    sizeSystem: json['sizeSystem'] as String,
    sizeValue: json['sizeValue'] as String,
    color: json['color'] as String,
    price: double.parse(json['price'] as String),
    stock: json['stock'] as int,
  );
  final String id, sizeSystem, sizeValue, color;
  final double price;
  final int stock;
}

class CatalogProduct {
  const CatalogProduct({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.brand,
    required this.category,
    required this.images,
    required this.variants,
  });
  factory CatalogProduct.fromJson(Map<String, dynamic> json) => CatalogProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    description: json['description'] as String?,
    brand: (json['brand'] as Map<String, dynamic>)['name'] as String,
    category: (json['category'] as Map<String, dynamic>)['name'] as String,
    images: (json['images'] as List<dynamic>)
        .map((image) => (image as Map<String, dynamic>)['url'] as String)
        .toList(growable: false),
    variants: (json['variants'] as List<dynamic>)
        .map(
          (variant) => CatalogVariant.fromJson(variant as Map<String, dynamic>),
        )
        .toList(growable: false),
  );
  final String id, name, slug, brand, category;
  final String? description;
  final List<String> images;
  final List<CatalogVariant> variants;
  Product toShopProduct() {
    final firstVariant = variants.isEmpty ? null : variants.first;
    final prices = variants.map((variant) => variant.price).toList()..sort();
    final remoteVariantIds = <int, String>{
      for (var index = 0; index < variants.length; index++)
        index: variants[index].id,
    };
    return Product(
      id: slug.hashCode,
      remoteId: id,
      remoteVariantIds: remoteVariantIds,
      brand: brand,
      name: name,
      category: category,
      price: firstVariant?.price ?? 0,
      oldPrice: prices.isEmpty ? (firstVariant?.price ?? 0) : prices.last,
      image: images.isEmpty ? '' : images.first,
      color: firstVariant?.color ?? '',
      lowStock:
          firstVariant != null &&
          firstVariant.stock > 0 &&
          firstVariant.stock <= 3,
      availableSizes: variants
          .map((variant) => int.tryParse(variant.sizeValue))
          .whereType<int>()
          .toList(growable: false),
    );
  }
}

class CatalogPage {
  const CatalogPage({
    required this.products,
    required this.page,
    required this.total,
    required this.totalPages,
  });
  factory CatalogPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    return CatalogPage(
      products: (json['data'] as List<dynamic>)
          .map(
            (product) =>
                CatalogProduct.fromJson(product as Map<String, dynamic>),
          )
          .toList(growable: false),
      page: pagination['page'] as int,
      total: pagination['total'] as int,
      totalPages: pagination['totalPages'] as int,
    );
  }
  final List<CatalogProduct> products;
  final int page, total, totalPages;
}

class CatalogRepository {
  CatalogRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;
  Future<CatalogPage> listProducts({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final parameters = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    };
    final payload = await _client.get(
      '/catalog/products?${Uri(queryParameters: parameters).query}',
    );
    return CatalogPage.fromJson(payload as Map<String, dynamic>);
  }

  Future<CatalogProduct> getProduct(String slug) async {
    final payload = await _client.get(
      '/catalog/products/${Uri.encodeComponent(slug)}',
    );
    return CatalogProduct.fromJson(payload as Map<String, dynamic>);
  }
}
