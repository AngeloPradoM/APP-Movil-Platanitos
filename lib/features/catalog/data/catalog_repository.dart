import 'dart:math' as math;

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
    this.comparePrice,
  });
  factory CatalogVariant.fromJson(Map<String, dynamic> json) => CatalogVariant(
    id: json['id'] as String,
    sizeSystem: json['sizeSystem'] as String,
    sizeValue: json['sizeValue'] as String,
    color: json['color'] as String,
    price: double.parse(json['price'] as String),
    comparePrice: double.tryParse(json['comparePrice'] as String? ?? ''),
    stock: json['stock'] as int,
  );
  final String id, sizeSystem, sizeValue, color;
  final double price;

  /// Precio anterior a la oferta; `null` si la variante no está rebajada.
  final double? comparePrice;
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

  /// Usa el color y sistema de talla de la primera variante; las tallas
  /// quedan ordenadas y cada índice conserva su variante y su stock.
  Product toShopProduct() {
    final firstVariant = variants.isEmpty ? null : variants.first;
    final color = firstVariant?.color ?? '';
    final system = firstVariant == null
        ? null
        : sizeSystemFromApi(firstVariant.sizeSystem);
    final selected = {
      for (final variant in variants)
        if (variant.color == color &&
            sizeSystemFromApi(variant.sizeSystem) == system)
          variant.sizeValue: variant,
    }.values.toList()..sort((a, b) => compareSizes(a.sizeValue, b.sizeValue));
    final price = selected.isEmpty
        ? 0.0
        : selected.map((variant) => variant.price).reduce(math.min);
    final comparePrices = selected
        .map((variant) => variant.comparePrice)
        .whereType<double>()
        .where((value) => value > price);
    return Product(
      id: slug.hashCode,
      remoteId: id,
      remoteVariantIds: {
        for (final (index, variant) in selected.indexed) index: variant.id,
      },
      variantStock: {
        for (final (index, variant) in selected.indexed) index: variant.stock,
      },
      brand: brand,
      name: name,
      category: category,
      price: price,
      oldPrice: comparePrices.fold(price, math.max),
      image: images.isEmpty ? '' : images.first,
      color: color,
      lowStock: selected.any(
        (variant) => variant.stock > 0 && variant.stock <= 3,
      ),
      sizeSystem: system ?? SizeSystem.eur,
      sizes: List.unmodifiable(selected.map((variant) => variant.sizeValue)),
      availableSizes: List.unmodifiable([
        for (final (index, variant) in selected.indexed)
          if (variant.stock > 0) index,
      ]),
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
