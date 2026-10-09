import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/shop_models.dart';
import '../../account/data/addresses_repository.dart';

class RemoteOrderItem {
  const RemoteOrderItem({
    required this.variantId,
    required this.productName,
    required this.productSlug,
    required this.image,
    required this.sizeSystem,
    required this.sizeValue,
    required this.color,
    required this.quantity,
    required this.unitPrice,
  });
  factory RemoteOrderItem.fromJson(Map<String, dynamic> json) =>
      RemoteOrderItem(
        variantId: json['variantId'] as String?,
        productName: json['productName'] as String,
        productSlug: json['productSlug'] as String?,
        image: json['image'] as String?,
        sizeSystem: json['sizeSystem'] as String,
        sizeValue: json['sizeValue'] as String,
        color: json['color'] as String,
        quantity: json['quantity'] as int,
        unitPrice: double.parse(json['unitPrice'] as String),
      );
  final String? variantId, productSlug, image;
  final String productName, sizeSystem, sizeValue, color;
  final int quantity;
  final double unitPrice;
}

class RemoteOrder {
  const RemoteOrder({
    required this.publicNumber,
    required this.status,
    required this.paymentMethod,
    required this.shipping,
    required this.createdAt,
    required this.items,
    this.address,
  });
  factory RemoteOrder.fromJson(Map<String, dynamic> json) => RemoteOrder(
    publicNumber: json['publicNumber'] as String,
    status: json['status'] as String,
    paymentMethod: json['paymentMethod'] as String,
    shipping: double.parse(json['shipping'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    address: json['address'] is Map
        ? addressFromJson(Map<String, dynamic>.from(json['address'] as Map))
        : null,
    items: (json['items'] as List<dynamic>)
        .map(
          (item) =>
              RemoteOrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );
  final String publicNumber, status, paymentMethod;
  final double shipping;
  final DateTime createdAt;
  final List<RemoteOrderItem> items;
  final ShippingAddress? address;
}

class OrdersRepository {
  OrdersRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  /// Convierte en pedido la bolsa guardada en el servidor.
  Future<RemoteOrder> create({
    required String accessToken,
    required String paymentMethod,
    String? addressId,
  }) async => _parse(
    await _client.post(
      '/orders',
      accessToken: accessToken,
      body: {'paymentMethod': paymentMethod, 'addressId': ?addressId},
    ),
  );

  Future<List<RemoteOrder>> list({required String accessToken}) async =>
      (await _client.get('/orders', accessToken: accessToken) as List<dynamic>)
          .map(_parse)
          .toList(growable: false);

  Future<RemoteOrder> updateStatus({
    required String accessToken,
    required String publicNumber,
    required String status,
  }) async => _parse(
    await _client.patch(
      '/orders/${Uri.encodeComponent(publicNumber)}/status',
      accessToken: accessToken,
      body: {'status': status},
    ),
  );

  RemoteOrder _parse(dynamic payload) =>
      RemoteOrder.fromJson(Map<String, dynamic>.from(payload as Map));
}
