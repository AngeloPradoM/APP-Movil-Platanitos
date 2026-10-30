import 'dart:typed_data';

import '../operations_models.dart';

abstract interface class DemoOperationsRepository {
  Future<List<DemoCartLine>> loadCart(String userId);
  Future<void> setCartItem(String userId, String variantId, int quantity);
  Future<DemoOrder> checkout({
    required String userId,
    required String paymentMethod,
    required int shippingCents,
    required String address,
  });
  Future<List<DemoOrder>> orders({String? userId});
  Future<void> cancelOrder(String orderId, String userId);

  Future<List<FulfillmentTask>> fulfillmentTasks();
  Future<void> startPreparation(String orderId, String workerId);
  Future<void> markPrepared(String orderId, String workerId);
  Future<void> dispatchOrder(
    String orderId,
    String workerId,
    String deliveryUserId,
  );

  Future<List<DeliveryTask>> deliveries(String deliveryUserId);
  Future<void> updateDelivery(String deliveryId, String status);
  Future<void> confirmDelivery({
    required String deliveryId,
    required String recipientName,
    required String signatureData,
    required Uint8List photoBytes,
  });
  Future<DeliveryEvidence?> deliveryEvidence(String deliveryId);
  Future<void> reportIncident(
    String deliveryId,
    String type,
    String description,
  );

  Future<List<SupportRequestRecord>> supportRequests({String? userId});
  Future<void> createSupportRequest({
    required String orderId,
    required String userId,
    required String type,
    required String reason,
  });
  Future<void> updateSupportRequest(String requestId, String status);

  Future<OperationsReport> report();

  Future<List<StoreReservation>> reservations();
  Future<void> createReservation({
    required String variantId,
    required String customerName,
    required int quantity,
    required String workerId,
  });
  Future<void> updateReservation(String reservationId, String status);
}
