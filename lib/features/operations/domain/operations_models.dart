import 'dart:typed_data';

class DemoCartLine {
  const DemoCartLine({required this.variantId, required this.quantity});
  final String variantId;
  final int quantity;
}

class DemoOrderLine {
  const DemoOrderLine({
    required this.variantId,
    required this.productName,
    required this.brand,
    required this.image,
    required this.sizeSystem,
    required this.sizeValue,
    required this.color,
    required this.unitPriceCents,
    required this.quantity,
  });
  final String? variantId;
  final String productName;
  final String brand;
  final String image;
  final String sizeSystem;
  final String sizeValue;
  final String color;
  final int unitPriceCents;
  final int quantity;
}

class DemoOrder {
  const DemoOrder({
    required this.id,
    required this.publicNumber,
    required this.userId,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingCents,
    required this.createdAt,
    required this.address,
    required this.items,
  });
  final String id;
  final String publicNumber;
  final String userId;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final int shippingCents;
  final DateTime createdAt;
  final String address;
  final List<DemoOrderLine> items;
  int get subtotalCents =>
      items.fold(0, (sum, item) => sum + item.unitPriceCents * item.quantity);
  int get totalCents => subtotalCents + shippingCents;
  int get units => items.fold(0, (sum, item) => sum + item.quantity);
}

class FulfillmentTask {
  const FulfillmentTask({
    required this.orderId,
    required this.publicNumber,
    required this.status,
    required this.createdAt,
    required this.units,
  });
  final String orderId;
  final String publicNumber;
  final String status;
  final DateTime createdAt;
  final int units;
}

class DeliveryTask {
  const DeliveryTask({
    required this.id,
    required this.orderId,
    required this.publicNumber,
    required this.assignedUserId,
    required this.status,
    required this.address,
    required this.assignedAt,
    this.hasEvidence = false,
    this.recipientName,
  });
  final String id;
  final String orderId;
  final String publicNumber;
  final String assignedUserId;
  final String status;
  final String address;
  final DateTime assignedAt;
  final bool hasEvidence;
  final String? recipientName;
}

class DeliveryEvidence {
  const DeliveryEvidence({
    required this.deliveryId,
    required this.recipientName,
    required this.signatureData,
    required this.photoBytes,
    required this.capturedAt,
  });

  final String deliveryId;
  final String recipientName;
  final String signatureData;
  final Uint8List photoBytes;
  final DateTime capturedAt;
}

class SupportRequestRecord {
  const SupportRequestRecord({
    required this.id,
    required this.orderId,
    required this.publicNumber,
    required this.userId,
    required this.type,
    required this.status,
    required this.reason,
    required this.createdAt,
  });
  final String id;
  final String orderId;
  final String publicNumber;
  final String userId;
  final String type;
  final String status;
  final String reason;
  final DateTime createdAt;
}

class OperationsReport {
  const OperationsReport({
    required this.orders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.lowStockVariants,
    required this.openSupportRequests,
    required this.activeDeliveries,
    required this.totalSalesCents,
  });
  final int orders;
  final int pendingOrders;
  final int deliveredOrders;
  final int lowStockVariants;
  final int openSupportRequests;
  final int activeDeliveries;
  final int totalSalesCents;
}

class StoreReservation {
  const StoreReservation({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.customerName,
    required this.quantity,
    required this.status,
    required this.expiresAt,
  });
  final String id;
  final String variantId;
  final String productName;
  final String customerName;
  final int quantity;
  final String status;
  final DateTime expiresAt;
}
