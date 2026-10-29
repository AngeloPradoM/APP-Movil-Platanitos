import 'dart:typed_data';

import '../../../core/network/access_token_store.dart';
import '../../../core/network/api_client.dart';
import '../domain/operations_models.dart';
import '../domain/repositories/demo_operations_repository.dart';

class RemoteOperationsRepository implements DemoOperationsRepository {
  RemoteOperationsRepository(this._client, this._tokens);
  final ApiClient _client;
  final AccessTokenStore _tokens;

  String get _token {
    final token = _tokens.value;
    if (token == null || token.isEmpty) {
      throw StateError('Inicia sesión para ver las operaciones.');
    }
    return token;
  }

  @override
  Future<OperationsReport> report() async {
    final raw = Map<String, dynamic>.from(
      await _client.get('/operations/report', accessToken: _token) as Map,
    );
    return OperationsReport(
      orders: raw['orders'] as int,
      pendingOrders: raw['pendingOrders'] as int,
      deliveredOrders: raw['deliveredOrders'] as int,
      lowStockVariants: raw['lowStockVariants'] as int,
      openSupportRequests: raw['openSupportRequests'] as int,
      activeDeliveries: raw['activeDeliveries'] as int,
      totalSalesCents: raw['totalSalesCents'] as int,
    );
  }

  @override
  Future<List<FulfillmentTask>> fulfillmentTasks() async {
    final payload = await _client.get(
      '/operations/fulfillment',
      accessToken: _token,
    );
    return [
      for (final raw in payload as List<dynamic>)
        FulfillmentTask(
          orderId: (raw as Map)['orderId'] as String,
          publicNumber: raw['publicNumber'] as String,
          status: raw['status'] as String,
          createdAt: DateTime.parse(raw['createdAt'] as String).toLocal(),
          units: raw['units'] as int,
        ),
    ];
  }

  @override
  Future<void> startPreparation(String orderId, String workerId) async {
    await _client.post(
      '/operations/fulfillment/${Uri.encodeComponent(orderId)}/start',
      accessToken: _token,
    );
  }

  @override
  Future<void> markPrepared(String orderId, String workerId) async {
    await _client.post(
      '/operations/fulfillment/${Uri.encodeComponent(orderId)}/ready',
      accessToken: _token,
    );
  }

  @override
  Future<void> dispatchOrder(
    String orderId,
    String workerId,
    String deliveryUserId,
  ) async {
    await _client.post(
      '/operations/fulfillment/${Uri.encodeComponent(orderId)}/dispatch',
      accessToken: _token,
    );
  }

  Future<void> markInTransit(String orderId) async {
    await _client.post(
      '/operations/fulfillment/${Uri.encodeComponent(orderId)}/transit',
      accessToken: _token,
    );
  }

  Future<void> markDelivered(String orderId) async {
    await _client.post(
      '/operations/fulfillment/${Uri.encodeComponent(orderId)}/deliver',
      accessToken: _token,
    );
  }

  @override
  Future<List<DemoCartLine>> loadCart(String userId) async => const [];

  @override
  Future<void> setCartItem(String userId, String variantId, int quantity) =>
      _unavailable();

  @override
  Future<DemoOrder> checkout({
    required String userId,
    required String paymentMethod,
    required int shippingCents,
    required String address,
  }) => _unavailable();

  @override
  Future<List<DemoOrder>> orders({String? userId}) async => const [];

  @override
  Future<void> cancelOrder(String orderId, String userId) => _unavailable();

  @override
  Future<List<DeliveryTask>> deliveries(String deliveryUserId) async =>
      const [];

  @override
  Future<void> updateDelivery(String deliveryId, String status) =>
      _unavailable();

  @override
  Future<void> confirmDelivery({
    required String deliveryId,
    required String recipientName,
    required String signatureData,
    required Uint8List photoBytes,
  }) => _unavailable();

  @override
  Future<DeliveryEvidence?> deliveryEvidence(String deliveryId) async => null;

  @override
  Future<void> reportIncident(
    String deliveryId,
    String type,
    String description,
  ) => _unavailable();

  @override
  Future<List<SupportRequestRecord>> supportRequests({String? userId}) async =>
      const [];

  @override
  Future<void> createSupportRequest({
    required String orderId,
    required String userId,
    required String type,
    required String reason,
  }) => _unavailable();

  @override
  Future<void> updateSupportRequest(String requestId, String status) =>
      _unavailable();

  @override
  Future<List<StoreReservation>> reservations() async => const [];

  @override
  Future<void> createReservation({
    required String variantId,
    required String customerName,
    required int quantity,
    required String workerId,
  }) => _unavailable();

  @override
  Future<void> updateReservation(String reservationId, String status) =>
      _unavailable();

  Future<Never> _unavailable() {
    throw StateError('Esta operación todavía no está en el servidor.');
  }
}
