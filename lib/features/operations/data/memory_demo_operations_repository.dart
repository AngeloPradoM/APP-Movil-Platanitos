import 'dart:typed_data';

import '../../../app/data/demo_data.dart' as demo;
import '../../../app/data/memory_demo_store.dart';
import '../../../app/models/shop_models.dart';
import '../domain/operations_models.dart';
import '../domain/repositories/demo_operations_repository.dart';

/// Implementación en memoria usada por Flutter Web. Mantiene las mismas
/// reglas que SQLite para que la demo se comporte igual en todas las plataformas.
class MemoryDemoOperationsRepository implements DemoOperationsRepository {
  MemoryDemoOperationsRepository(this.store);

  final DemoMemoryStore store;

  String _id(String prefix) => '$prefix-${++store.sequence}';

  ({Product product, int sizeIndex}) _variant(String variantId) {
    for (final product in demo.products) {
      for (final sizeIndex in product.availableSizes) {
        if (DemoMemoryStore.variantId(product, sizeIndex) == variantId) {
          return (product: product, sizeIndex: sizeIndex);
        }
      }
    }
    throw StateError('La variante no existe.');
  }

  int _available(String variantId) =>
      (store.stock[variantId] ?? 0) - (store.reservedStock[variantId] ?? 0);

  @override
  Future<List<DemoCartLine>> loadCart(String userId) async => [
    for (final entry in (store.carts[userId] ?? const {}).entries)
      DemoCartLine(variantId: entry.key, quantity: entry.value),
  ];

  @override
  Future<void> setCartItem(
    String userId,
    String variantId,
    int quantity,
  ) async {
    _variant(variantId);
    if (quantity < 0 || quantity > 20) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    if (quantity > _available(variantId)) {
      throw StateError('No hay stock suficiente para esta talla.');
    }
    final cart = store.carts.putIfAbsent(userId, () => {});
    if (quantity == 0) {
      cart.remove(variantId);
    } else {
      cart[variantId] = quantity;
    }
  }

  @override
  Future<DemoOrder> checkout({
    required String userId,
    required String paymentMethod,
    required int shippingCents,
    required String address,
  }) async {
    final cart = store.carts[userId];
    if (cart == null || cart.isEmpty) throw StateError('La bolsa está vacía.');
    for (final entry in cart.entries) {
      if (entry.value > _available(entry.key)) {
        throw StateError('El stock cambió. Revisa tu bolsa.');
      }
    }
    final lines = <DemoOrderLine>[];
    for (final entry in cart.entries) {
      final match = _variant(entry.key);
      final product = match.product;
      store.reservedStock[entry.key] =
          (store.reservedStock[entry.key] ?? 0) + entry.value;
      lines.add(
        DemoOrderLine(
          variantId: entry.key,
          productName: product.name,
          brand: product.brand,
          image: product.image,
          sizeSystem: product.sizeSystem.name.toUpperCase(),
          sizeValue: product.sizes[match.sizeIndex],
          color: product.color,
          unitPriceCents: (product.price * 100).round(),
          quantity: entry.value,
        ),
      );
    }
    final sequence = ++store.sequence;
    final order = DemoOrder(
      id: 'order-$sequence',
      publicNumber: 'PL-$sequence',
      userId: userId,
      status: 'PENDING',
      paymentStatus: paymentMethod == 'CASH'
          ? 'PENDING_SIMULATED'
          : 'APPROVED_SIMULATED',
      paymentMethod: paymentMethod,
      shippingCents: shippingCents,
      createdAt: DateTime.now(),
      address: address,
      items: List.unmodifiable(lines),
    );
    store.orders.insert(0, order);
    store.preparationStatus[order.id] = 'PENDING';
    cart.clear();
    return order;
  }

  @override
  Future<List<DemoOrder>> orders({String? userId}) async => store.orders
      .where((order) => userId == null || order.userId == userId)
      .toList(growable: false);

  DemoOrder _order(String id) =>
      store.orders.firstWhere((order) => order.id == id);

  void _replaceOrder(DemoOrder current, String status) {
    final index = store.orders.indexOf(current);
    store.orders[index] = DemoOrder(
      id: current.id,
      publicNumber: current.publicNumber,
      userId: current.userId,
      status: status,
      paymentStatus: current.paymentStatus,
      paymentMethod: current.paymentMethod,
      shippingCents: current.shippingCents,
      createdAt: current.createdAt,
      address: current.address,
      items: current.items,
    );
  }

  @override
  Future<void> cancelOrder(String orderId, String userId) async {
    final order = _order(orderId);
    if (order.userId != userId ||
        !{'PENDING', 'PREPARING', 'PREPARED'}.contains(order.status)) {
      throw StateError('El pedido ya no puede cancelarse.');
    }
    for (final item in order.items) {
      if (item.variantId != null) {
        store.reservedStock[item.variantId!] =
            (store.reservedStock[item.variantId!] ?? 0) - item.quantity;
      }
    }
    _replaceOrder(order, 'CANCELLED');
    store.preparationStatus[orderId] = 'CANCELLED';
  }

  @override
  Future<List<FulfillmentTask>> fulfillmentTasks() async => [
    for (final order in store.orders)
      if (order.status != 'CANCELLED' && order.status != 'DELIVERED')
        FulfillmentTask(
          orderId: order.id,
          publicNumber: order.publicNumber,
          status: store.preparationStatus[order.id] ?? order.status,
          createdAt: order.createdAt,
          units: order.units,
        ),
  ];

  void _requirePreparation(String orderId, String expected, String next) {
    if (store.preparationStatus[orderId] != expected) {
      throw StateError('La tarea no está en el estado esperado.');
    }
    store.preparationStatus[orderId] = next;
    _replaceOrder(
      _order(orderId),
      next == 'PREPARED' ? 'PREPARED' : 'PREPARING',
    );
  }

  @override
  Future<void> startPreparation(String orderId, String workerId) async =>
      _requirePreparation(orderId, 'PENDING', 'PREPARING');

  @override
  Future<void> markPrepared(String orderId, String workerId) async =>
      _requirePreparation(orderId, 'PREPARING', 'PREPARED');

  @override
  Future<void> dispatchOrder(
    String orderId,
    String workerId,
    String deliveryUserId,
  ) async {
    if (store.preparationStatus[orderId] != 'PREPARED') {
      throw StateError('El pedido todavía no está preparado.');
    }
    final order = _order(orderId);
    for (final item in order.items) {
      final variantId = item.variantId;
      if (variantId == null) continue;
      store.stock[variantId] = (store.stock[variantId] ?? 0) - item.quantity;
      store.reservedStock[variantId] =
          (store.reservedStock[variantId] ?? 0) - item.quantity;
    }
    store.preparationStatus[orderId] = 'DISPATCHED';
    _replaceOrder(order, 'DISPATCHED');
    store.deliveries.insert(
      0,
      DeliveryTask(
        id: _id('delivery'),
        orderId: order.id,
        publicNumber: order.publicNumber,
        assignedUserId: deliveryUserId,
        status: 'ASSIGNED',
        address: order.address,
        assignedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<DeliveryTask>> deliveries(String deliveryUserId) async => store
      .deliveries
      .where((delivery) => delivery.assignedUserId == deliveryUserId)
      .toList(growable: false);

  @override
  Future<void> updateDelivery(String deliveryId, String status) async {
    final index = store.deliveries.indexWhere((item) => item.id == deliveryId);
    if (index < 0) throw StateError('La entrega no existe.');
    final current = store.deliveries[index];
    final allowed = <String, Set<String>>{
      'ASSIGNED': {'PICKED_UP'},
      'PICKED_UP': {'IN_TRANSIT'},
      'IN_TRANSIT': {'FAILED'},
      'FAILED': {'IN_TRANSIT'},
    };
    if (!(allowed[current.status]?.contains(status) ?? false)) {
      throw StateError('Transición de entrega no válida.');
    }
    store.deliveries[index] = DeliveryTask(
      id: current.id,
      orderId: current.orderId,
      publicNumber: current.publicNumber,
      assignedUserId: current.assignedUserId,
      status: status,
      address: current.address,
      assignedAt: current.assignedAt,
      hasEvidence: current.hasEvidence,
    );
    final orderStatus = switch (status) {
      'FAILED' => 'DELIVERY_FAILED',
      _ => 'IN_TRANSIT',
    };
    _replaceOrder(_order(current.orderId), orderStatus);
  }

  @override
  Future<void> confirmDelivery({
    required String deliveryId,
    required String recipientName,
    required String signatureData,
    required Uint8List photoBytes,
  }) async {
    final index = store.deliveries.indexWhere((item) => item.id == deliveryId);
    if (index < 0 || store.deliveries[index].status != 'IN_TRANSIT') {
      throw StateError('La entrega debe estar en camino para confirmarse.');
    }
    if (recipientName.trim().isEmpty ||
        signatureData.trim().isEmpty ||
        photoBytes.isEmpty) {
      throw ArgumentError('La evidencia de entrega está incompleta.');
    }
    final current = store.deliveries[index];
    final evidence = DeliveryEvidence(
      deliveryId: deliveryId,
      recipientName: recipientName.trim(),
      signatureData: signatureData,
      photoBytes: Uint8List.fromList(photoBytes),
      capturedAt: DateTime.now(),
    );
    store.deliveryEvidence[deliveryId] = evidence;
    store.deliveries[index] = DeliveryTask(
      id: current.id,
      orderId: current.orderId,
      publicNumber: current.publicNumber,
      assignedUserId: current.assignedUserId,
      status: 'DELIVERED',
      address: current.address,
      assignedAt: current.assignedAt,
      hasEvidence: true,
    );
    _replaceOrder(_order(current.orderId), 'DELIVERED');
  }

  @override
  Future<DeliveryEvidence?> deliveryEvidence(String deliveryId) async =>
      store.deliveryEvidence[deliveryId];

  @override
  Future<void> reportIncident(
    String deliveryId,
    String type,
    String description,
  ) async {
    if (description.trim().isEmpty) {
      throw ArgumentError('Describe la incidencia.');
    }
    if (!store.deliveries.any((item) => item.id == deliveryId)) {
      throw StateError('La entrega no existe.');
    }
    store.incidents.add('$deliveryId|$type|${description.trim()}');
  }

  @override
  Future<List<SupportRequestRecord>> supportRequests({String? userId}) async =>
      store.supportRequests
          .where((request) => userId == null || request.userId == userId)
          .toList(growable: false);

  @override
  Future<void> createSupportRequest({
    required String orderId,
    required String userId,
    required String type,
    required String reason,
  }) async {
    final order = _order(orderId);
    if (order.userId != userId || reason.trim().isEmpty) {
      throw StateError('No se puede registrar la solicitud.');
    }
    store.supportRequests.insert(
      0,
      SupportRequestRecord(
        id: _id('support'),
        orderId: orderId,
        publicNumber: order.publicNumber,
        userId: userId,
        type: type,
        status: 'REGISTERED',
        reason: reason.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateSupportRequest(String requestId, String status) async {
    final index = store.supportRequests.indexWhere(
      (item) => item.id == requestId,
    );
    if (index < 0) throw StateError('La solicitud no existe.');
    final current = store.supportRequests[index];
    final allowed = <String, String>{
      'REGISTERED': 'IN_REVIEW',
      'IN_REVIEW': 'RESOLVED',
    };
    if (allowed[current.status] != status) {
      throw StateError('Transición de atención no permitida.');
    }
    store.supportRequests[index] = SupportRequestRecord(
      id: current.id,
      orderId: current.orderId,
      publicNumber: current.publicNumber,
      userId: current.userId,
      type: current.type,
      status: status,
      reason: current.reason,
      createdAt: current.createdAt,
    );
  }

  @override
  Future<OperationsReport> report() async => OperationsReport(
    orders: store.orders.length,
    pendingOrders: store.orders
        .where((item) => !{'DELIVERED', 'CANCELLED'}.contains(item.status))
        .length,
    deliveredOrders: store.orders
        .where((item) => item.status == 'DELIVERED')
        .length,
    lowStockVariants: store.stock.keys
        .where((id) => _available(id) <= 3)
        .length,
    openSupportRequests: store.supportRequests
        .where((item) => !{'REJECTED', 'RESOLVED'}.contains(item.status))
        .length,
    activeDeliveries: store.deliveries
        .where((item) => item.status != 'DELIVERED')
        .length,
    totalSalesCents: store.orders
        .where((item) => item.status != 'CANCELLED')
        .fold(0, (sum, item) => sum + item.totalCents),
  );

  @override
  Future<List<StoreReservation>> reservations() async =>
      List.unmodifiable(store.reservations);

  @override
  Future<void> createReservation({
    required String variantId,
    required String customerName,
    required int quantity,
    required String workerId,
  }) async {
    final match = _variant(variantId);
    if (quantity <= 0 || quantity > _available(variantId)) {
      throw StateError('No hay stock disponible para la reserva.');
    }
    store.reservedStock[variantId] =
        (store.reservedStock[variantId] ?? 0) + quantity;
    store.reservations.insert(
      0,
      StoreReservation(
        id: _id('reservation'),
        variantId: variantId,
        productName: match.product.name,
        customerName: customerName.trim(),
        quantity: quantity,
        status: 'ACTIVE',
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      ),
    );
  }

  @override
  Future<void> updateReservation(String reservationId, String status) async {
    final index = store.reservations.indexWhere(
      (item) => item.id == reservationId,
    );
    if (index < 0 || store.reservations[index].status != 'ACTIVE') {
      throw StateError('La reserva ya fue atendida.');
    }
    final current = store.reservations[index];
    if (status == 'COLLECTED') {
      store.stock[current.variantId] =
          (store.stock[current.variantId] ?? 0) - current.quantity;
    }
    store.reservedStock[current.variantId] =
        (store.reservedStock[current.variantId] ?? 0) - current.quantity;
    store.reservations[index] = StoreReservation(
      id: current.id,
      variantId: current.variantId,
      productName: current.productName,
      customerName: current.customerName,
      quantity: current.quantity,
      status: status,
      expiresAt: current.expiresAt,
    );
  }
}
