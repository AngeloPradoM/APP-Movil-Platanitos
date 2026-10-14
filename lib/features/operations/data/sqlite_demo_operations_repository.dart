import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/operations_models.dart';
import '../domain/repositories/demo_operations_repository.dart';

class SqliteDemoOperationsRepository implements DemoOperationsRepository {
  SqliteDemoOperationsRepository(this._appDatabase);
  final AppDatabase _appDatabase;

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<List<DemoCartLine>> loadCart(String userId) async {
    final rows = await _appDatabase.database.query(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id',
    );
    return rows
        .map(
          (row) => DemoCartLine(
            variantId: row['variant_id'] as String,
            quantity: row['quantity'] as int,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> setCartItem(
    String userId,
    String variantId,
    int quantity,
  ) async {
    if (quantity < 0) throw ArgumentError.value(quantity, 'quantity');
    if (quantity == 0) {
      await _appDatabase.database.delete(
        'cart_items',
        where: 'user_id = ? AND variant_id = ?',
        whereArgs: [userId, variantId],
      );
      return;
    }
    if (quantity > 20) throw StateError('La cantidad máxima es 20.');
    final stock = await _appDatabase.database.query(
      'product_variants',
      columns: ['physical_stock', 'reserved_stock'],
      where: 'id = ?',
      whereArgs: [variantId],
      limit: 1,
    );
    if (stock.isEmpty) throw StateError('La variante no existe.');
    final physical = stock.first['physical_stock'] as int;
    final reserved = stock.first['reserved_stock'] as int;
    final available = physical - reserved;
    if (quantity > available) throw StateError('Stock insuficiente.');
    await _appDatabase.database.insert('cart_items', {
      'user_id': userId,
      'variant_id': variantId,
      'quantity': quantity,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<DemoOrder> checkout({
    required String userId,
    required String paymentMethod,
    required int shippingCents,
    required String address,
  }) => _appDatabase.database.transaction((transaction) async {
    final lines = await transaction.rawQuery(
      '''
      SELECT c.variant_id, c.quantity, v.size_system, v.size_value, v.color,
             v.physical_stock, v.reserved_stock, p.name, p.brand, p.image,
             p.price_cents
      FROM cart_items c
      JOIN product_variants v ON v.id = c.variant_id
      JOIN products p ON p.id = v.product_id
      WHERE c.user_id = ?
      ORDER BY c.id
    ''',
      [userId],
    );
    if (lines.isEmpty) throw StateError('La bolsa está vacía.');
    for (final line in lines) {
      final physical = line['physical_stock'] as int;
      final reserved = line['reserved_stock'] as int;
      final available = physical - reserved;
      if (line['quantity'] as int > available) {
        throw StateError('Stock insuficiente para ${line['name']}.');
      }
    }
    final id = _id('order');
    final publicNumber =
        'PL-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedMethod = paymentMethod.toUpperCase();
    final paymentStatus = normalizedMethod == 'CASH'
        ? 'PENDING_SIMULATED'
        : 'APPROVED_SIMULATED';
    await transaction.insert('orders', {
      'id': id,
      'public_number': publicNumber,
      'user_id': userId,
      'status': 'PENDING',
      'payment_status': paymentStatus,
      'payment_method': normalizedMethod,
      'shipping_cents': shippingCents,
      'address': address,
      'created_at': now,
    });
    var subtotal = 0;
    for (final line in lines) {
      final quantity = line['quantity'] as int;
      final price = line['price_cents'] as int;
      subtotal += price * quantity;
      final updated = await transaction.rawUpdate(
        '''
        UPDATE product_variants
        SET reserved_stock = reserved_stock + ?
        WHERE id = ? AND physical_stock - reserved_stock >= ?
      ''',
        [quantity, line['variant_id'], quantity],
      );
      if (updated != 1) throw StateError('El stock cambió durante la compra.');
      await transaction.insert('order_items', {
        'order_id': id,
        'variant_id': line['variant_id'],
        'product_name': line['name'],
        'size_system': line['size_system'],
        'size_value': line['size_value'],
        'color': line['color'],
        'unit_price_cents': price,
        'quantity': quantity,
      });
    }
    await transaction.insert('simulated_payments', {
      'id': _id('payment'),
      'order_id': id,
      'method': normalizedMethod,
      'status': paymentStatus,
      'amount_cents': subtotal + shippingCents,
      'message': 'Simulación académica; no se procesó dinero real.',
      'created_at': now,
    });
    await transaction.insert('order_preparations', {
      'order_id': id,
      'status': 'PENDING',
    });
    await transaction.delete(
      'cart_items',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return _readOrder(transaction, id);
  });

  @override
  Future<List<DemoOrder>> orders({String? userId}) async {
    final rows = await _appDatabase.database.query(
      'orders',
      columns: ['id'],
      where: userId == null ? null : 'user_id = ?',
      whereArgs: userId == null ? null : [userId],
      orderBy: 'created_at DESC',
    );
    return Future.wait(
      rows.map((row) => _readOrder(_appDatabase.database, row['id'] as String)),
    );
  }

  Future<DemoOrder> _readOrder(DatabaseExecutor executor, String id) async {
    final rows = await executor.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('El pedido no existe.');
    final row = rows.first;
    final items = await executor.rawQuery(
      '''
      SELECT oi.*, COALESCE(p.brand, '') AS brand,
             COALESCE(p.image, '') AS image
      FROM order_items oi
      LEFT JOIN product_variants v ON v.id = oi.variant_id
      LEFT JOIN products p ON p.id = v.product_id
      WHERE oi.order_id = ?
      ORDER BY oi.id
    ''',
      [id],
    );
    return DemoOrder(
      id: id,
      publicNumber: row['public_number'] as String,
      userId: row['user_id'] as String,
      status: row['status'] as String,
      paymentStatus: row['payment_status'] as String,
      paymentMethod: row['payment_method'] as String,
      shippingCents: row['shipping_cents'] as int,
      address: row['address'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      items: items
          .map(
            (item) => DemoOrderLine(
              variantId: item['variant_id'] as String?,
              productName: item['product_name'] as String,
              brand: item['brand'] as String,
              image: item['image'] as String,
              sizeSystem: item['size_system'] as String,
              sizeValue: item['size_value'] as String,
              color: item['color'] as String,
              unitPriceCents: item['unit_price_cents'] as int,
              quantity: item['quantity'] as int,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<void> cancelOrder(String orderId, String userId) =>
      _appDatabase.database.transaction((transaction) async {
        final orders = await transaction.query(
          'orders',
          columns: ['status'],
          where: 'id = ? AND user_id = ?',
          whereArgs: [orderId, userId],
          limit: 1,
        );
        if (orders.isEmpty) throw StateError('El pedido no existe.');
        if (!const [
          'PENDING',
          'PREPARING',
          'PREPARED',
        ].contains(orders.first['status'])) {
          throw StateError('El pedido ya no puede cancelarse.');
        }
        await _releaseOrderReservations(transaction, orderId);
        await transaction.update(
          'orders',
          {'status': 'CANCELLED', 'payment_status': 'CANCELLED'},
          where: 'id = ?',
          whereArgs: [orderId],
        );
        await transaction.update(
          'order_preparations',
          {'status': 'CANCELLED'},
          where: 'order_id = ?',
          whereArgs: [orderId],
        );
        await transaction.update(
          'simulated_payments',
          {'status': 'CANCELLED'},
          where: 'order_id = ?',
          whereArgs: [orderId],
        );
      });

  Future<void> _releaseOrderReservations(
    DatabaseExecutor executor,
    String orderId,
  ) async {
    final items = await executor.query(
      'order_items',
      columns: ['variant_id', 'quantity'],
      where: 'order_id = ? AND variant_id IS NOT NULL',
      whereArgs: [orderId],
    );
    for (final item in items) {
      await executor.rawUpdate(
        '''
        UPDATE product_variants
        SET reserved_stock = MAX(0, reserved_stock - ?)
        WHERE id = ?
      ''',
        [item['quantity'], item['variant_id']],
      );
    }
  }

  @override
  Future<List<FulfillmentTask>> fulfillmentTasks() async {
    final rows = await _appDatabase.database.rawQuery('''
      SELECT o.id, o.public_number, p.status, o.created_at,
             COALESCE(SUM(oi.quantity), 0) AS units
      FROM orders o
      JOIN order_preparations p ON p.order_id = o.id
      LEFT JOIN order_items oi ON oi.order_id = o.id
      WHERE p.status != 'CANCELLED'
      GROUP BY o.id, o.public_number, p.status, o.created_at
      ORDER BY o.created_at DESC
    ''');
    return rows
        .map(
          (row) => FulfillmentTask(
            orderId: row['id'] as String,
            publicNumber: row['public_number'] as String,
            status: row['status'] as String,
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
            units: row['units'] as int,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> startPreparation(String orderId, String workerId) async {
    final changed = await _appDatabase.database.update(
      'order_preparations',
      {
        'status': 'PREPARING',
        'assigned_user_id': workerId,
        'started_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: "order_id = ? AND status = 'PENDING'",
      whereArgs: [orderId],
    );
    if (changed != 1) throw StateError('El pedido no está pendiente.');
    await _appDatabase.database.update(
      'orders',
      {'status': 'PREPARING'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  @override
  Future<void> markPrepared(String orderId, String workerId) =>
      _appDatabase.database.transaction((transaction) async {
        final changed = await transaction.update(
          'order_preparations',
          {
            'status': 'PREPARED',
            'assigned_user_id': workerId,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: "order_id = ? AND status = 'PREPARING'",
          whereArgs: [orderId],
        );
        if (changed != 1) throw StateError('El pedido no está en preparación.');
        await transaction.update(
          'orders',
          {'status': 'PREPARED'},
          where: 'id = ?',
          whereArgs: [orderId],
        );
      });

  @override
  Future<void> dispatchOrder(
    String orderId,
    String workerId,
    String deliveryUserId,
  ) => _appDatabase.database.transaction((transaction) async {
    final preparation = await transaction.query(
      'order_preparations',
      columns: ['status'],
      where: 'order_id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    if (preparation.isEmpty || preparation.first['status'] != 'PREPARED') {
      throw StateError('El pedido debe estar preparado antes del despacho.');
    }
    final items = await transaction.query(
      'order_items',
      columns: ['variant_id', 'quantity'],
      where: 'order_id = ? AND variant_id IS NOT NULL',
      whereArgs: [orderId],
    );
    for (final item in items) {
      final quantity = item['quantity'] as int;
      final changed = await transaction.rawUpdate(
        '''
        UPDATE product_variants
        SET physical_stock = physical_stock - ?,
            reserved_stock = reserved_stock - ?
        WHERE id = ? AND physical_stock >= ? AND reserved_stock >= ?
      ''',
        [quantity, quantity, item['variant_id'], quantity, quantity],
      );
      if (changed != 1) throw StateError('No se pudo descontar el inventario.');
      await transaction.insert('stock_movements', {
        'variant_id': item['variant_id'],
        'type': 'exit',
        'quantity': quantity,
        'reason': 'Despacho de pedido',
        'responsible_user_id': workerId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
    final deliveryId = _id('delivery');
    final now = DateTime.now().toUtc().toIso8601String();
    await transaction.insert('deliveries', {
      'id': deliveryId,
      'order_id': orderId,
      'assigned_user_id': deliveryUserId,
      'status': 'ASSIGNED',
      'assigned_at': now,
    });
    await transaction.insert('delivery_events', {
      'delivery_id': deliveryId,
      'status': 'ASSIGNED',
      'note': 'Pedido asignado para reparto.',
      'created_at': now,
    });
    await transaction.update(
      'orders',
      {'status': 'DISPATCHED'},
      where: 'id = ?',
      whereArgs: [orderId],
    );
    await transaction.update(
      'order_preparations',
      {'status': 'DISPATCHED'},
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  });

  @override
  Future<List<DeliveryTask>> deliveries(String deliveryUserId) async {
    final rows = await _appDatabase.database.rawQuery(
      '''
      SELECT d.*, o.public_number, o.address,
             EXISTS(
               SELECT 1 FROM delivery_evidence e WHERE e.delivery_id = d.id
             ) AS has_evidence
      FROM deliveries d JOIN orders o ON o.id = d.order_id
      WHERE d.assigned_user_id = ?
      ORDER BY d.assigned_at DESC
    ''',
      [deliveryUserId],
    );
    return rows
        .map(
          (row) => DeliveryTask(
            id: row['id'] as String,
            orderId: row['order_id'] as String,
            publicNumber: row['public_number'] as String,
            assignedUserId: row['assigned_user_id'] as String,
            status: row['status'] as String,
            address: row['address'] as String,
            assignedAt: DateTime.parse(row['assigned_at'] as String).toLocal(),
            hasEvidence: (row['has_evidence'] as int) == 1,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> updateDelivery(String deliveryId, String status) =>
      _appDatabase.database.transaction((transaction) async {
        final rows = await transaction.query(
          'deliveries',
          columns: ['order_id', 'status'],
          where: 'id = ?',
          whereArgs: [deliveryId],
          limit: 1,
        );
        if (rows.isEmpty) throw StateError('La entrega no existe.');
        final current = rows.first['status'] as String;
        final allowed = <String, Set<String>>{
          'ASSIGNED': {'PICKED_UP'},
          'PICKED_UP': {'IN_TRANSIT'},
          'IN_TRANSIT': {'FAILED'},
          'FAILED': {'IN_TRANSIT'},
        };
        if (!(allowed[current]?.contains(status) ?? false)) {
          throw StateError('Transición de entrega no permitida.');
        }
        final now = DateTime.now().toUtc().toIso8601String();
        await transaction.update(
          'deliveries',
          {'status': status, if (status == 'DELIVERED') 'delivered_at': now},
          where: 'id = ?',
          whereArgs: [deliveryId],
        );
        await transaction.insert('delivery_events', {
          'delivery_id': deliveryId,
          'status': status,
          'note': 'Actualización demostrativa de reparto.',
          'created_at': now,
        });
        final orderStatus = switch (status) {
          'DELIVERED' => 'DELIVERED',
          'FAILED' => 'DELIVERY_FAILED',
          _ => 'IN_TRANSIT',
        };
        await transaction.update(
          'orders',
          {'status': orderStatus},
          where: 'id = ?',
          whereArgs: [rows.first['order_id']],
        );
      });

  @override
  Future<void> confirmDelivery({
    required String deliveryId,
    required String recipientName,
    required String signatureData,
    required Uint8List photoBytes,
  }) => _appDatabase.database.transaction((transaction) async {
    if (recipientName.trim().isEmpty ||
        signatureData.trim().isEmpty ||
        photoBytes.isEmpty) {
      throw ArgumentError('La evidencia de entrega está incompleta.');
    }
    final rows = await transaction.query(
      'deliveries',
      columns: ['order_id', 'status'],
      where: 'id = ?',
      whereArgs: [deliveryId],
      limit: 1,
    );
    if (rows.isEmpty || rows.single['status'] != 'IN_TRANSIT') {
      throw StateError('La entrega debe estar en camino para confirmarse.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    await transaction.insert('delivery_evidence', {
      'delivery_id': deliveryId,
      'recipient_name': recipientName.trim(),
      'signature_data': signatureData,
      'photo_bytes': photoBytes,
      'captured_at': now,
    });
    await transaction.update(
      'deliveries',
      {'status': 'DELIVERED', 'delivered_at': now},
      where: 'id = ?',
      whereArgs: [deliveryId],
    );
    await transaction.insert('delivery_events', {
      'delivery_id': deliveryId,
      'status': 'DELIVERED',
      'note': 'Entrega confirmada con firma y fotografía.',
      'created_at': now,
    });
    await transaction.update(
      'orders',
      {'status': 'DELIVERED'},
      where: 'id = ?',
      whereArgs: [rows.single['order_id']],
    );
  });

  @override
  Future<DeliveryEvidence?> deliveryEvidence(String deliveryId) async {
    final rows = await _appDatabase.database.query(
      'delivery_evidence',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    return DeliveryEvidence(
      deliveryId: deliveryId,
      recipientName: row['recipient_name'] as String,
      signatureData: row['signature_data'] as String,
      photoBytes: Uint8List.fromList(row['photo_bytes'] as List<int>),
      capturedAt: DateTime.parse(row['captured_at'] as String).toLocal(),
    );
  }

  @override
  Future<void> reportIncident(
    String deliveryId,
    String type,
    String description,
  ) async {
    if (description.trim().isEmpty) throw ArgumentError.value(description);
    await _appDatabase.database.insert('incidents', {
      'id': _id('incident'),
      'delivery_id': deliveryId,
      'type': type,
      'description': description.trim(),
      'status': 'OPEN',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<SupportRequestRecord>> supportRequests({String? userId}) async {
    final rows = await _appDatabase.database.rawQuery('''
      SELECT s.*, o.public_number
      FROM support_requests s JOIN orders o ON o.id = s.order_id
      ${userId == null ? '' : 'WHERE s.user_id = ?'}
      ORDER BY s.created_at DESC
    ''', userId == null ? null : [userId]);
    return rows
        .map(
          (row) => SupportRequestRecord(
            id: row['id'] as String,
            orderId: row['order_id'] as String,
            publicNumber: row['public_number'] as String,
            userId: row['user_id'] as String,
            type: row['type'] as String,
            status: row['status'] as String,
            reason: row['reason'] as String,
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> createSupportRequest({
    required String orderId,
    required String userId,
    required String type,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) throw ArgumentError.value(reason);
    final order = await _appDatabase.database.query(
      'orders',
      columns: ['id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [orderId, userId],
      limit: 1,
    );
    if (order.isEmpty) throw StateError('El pedido no pertenece al cliente.');
    final now = DateTime.now().toUtc().toIso8601String();
    await _appDatabase.database.insert('support_requests', {
      'id': _id('support'),
      'order_id': orderId,
      'user_id': userId,
      'type': type,
      'status': 'REGISTERED',
      'reason': reason.trim(),
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateSupportRequest(String requestId, String status) =>
      _appDatabase.database.transaction((transaction) async {
        final rows = await transaction.query(
          'support_requests',
          columns: ['status'],
          where: 'id = ?',
          whereArgs: [requestId],
          limit: 1,
        );
        if (rows.isEmpty) throw StateError('La solicitud no existe.');
        final current = rows.single['status'] as String;
        final allowed = <String, String>{
          'REGISTERED': 'IN_REVIEW',
          'IN_REVIEW': 'RESOLVED',
        };
        if (allowed[current] != status) {
          throw StateError('Transición de atención no permitida.');
        }
        await transaction.update(
          'support_requests',
          {
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [requestId],
        );
      });

  @override
  Future<OperationsReport> report() async {
    Future<int> count(String sql, [List<Object?>? args]) async =>
        Sqflite.firstIntValue(
          await _appDatabase.database.rawQuery(sql, args),
        ) ??
        0;
    return OperationsReport(
      orders: await count('SELECT COUNT(*) FROM orders'),
      pendingOrders: await count(
        "SELECT COUNT(*) FROM orders WHERE status NOT IN ('DELIVERED', 'CANCELLED')",
      ),
      deliveredOrders: await count(
        "SELECT COUNT(*) FROM orders WHERE status = 'DELIVERED'",
      ),
      lowStockVariants: await count(
        'SELECT COUNT(*) FROM product_variants WHERE physical_stock - reserved_stock <= 3',
      ),
      openSupportRequests: await count(
        "SELECT COUNT(*) FROM support_requests WHERE status NOT IN ('REJECTED', 'RESOLVED')",
      ),
      activeDeliveries: await count(
        "SELECT COUNT(*) FROM deliveries WHERE status != 'DELIVERED'",
      ),
      totalSalesCents: await count('''
        SELECT COALESCE(SUM(amount_cents), 0) FROM simulated_payments
        WHERE status = 'APPROVED_SIMULATED'
      '''),
    );
  }

  @override
  Future<List<StoreReservation>> reservations() async {
    final rows = await _appDatabase.database.rawQuery('''
      SELECT r.*, p.name AS product_name
      FROM store_reservations r
      JOIN product_variants v ON v.id = r.variant_id
      JOIN products p ON p.id = v.product_id
      ORDER BY r.created_at DESC
    ''');
    return rows
        .map(
          (row) => StoreReservation(
            id: row['id'] as String,
            variantId: row['variant_id'] as String,
            productName: row['product_name'] as String,
            customerName: row['customer_name'] as String,
            quantity: row['quantity'] as int,
            status: row['status'] as String,
            expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> createReservation({
    required String variantId,
    required String customerName,
    required int quantity,
    required String workerId,
  }) => _appDatabase.database.transaction((transaction) async {
    if (quantity <= 0 || customerName.trim().isEmpty) {
      throw ArgumentError('Datos de reserva inválidos.');
    }
    final changed = await transaction.rawUpdate(
      '''
      UPDATE product_variants
      SET reserved_stock = reserved_stock + ?
      WHERE id = ? AND physical_stock - reserved_stock >= ?
    ''',
      [quantity, variantId, quantity],
    );
    if (changed != 1) throw StateError('Stock insuficiente para la reserva.');
    final now = DateTime.now();
    await transaction.insert('store_reservations', {
      'id': _id('reservation'),
      'variant_id': variantId,
      'customer_name': customerName.trim(),
      'quantity': quantity,
      'status': 'ACTIVE',
      'worker_id': workerId,
      'created_at': now.toUtc().toIso8601String(),
      'expires_at': now
          .add(const Duration(hours: 24))
          .toUtc()
          .toIso8601String(),
    });
  });

  @override
  Future<void> updateReservation(String reservationId, String status) =>
      _appDatabase.database.transaction((transaction) async {
        if (!const ['COLLECTED', 'CANCELLED'].contains(status)) {
          throw StateError('Estado de reserva no permitido.');
        }
        final rows = await transaction.query(
          'store_reservations',
          columns: ['variant_id', 'quantity', 'status'],
          where: 'id = ?',
          whereArgs: [reservationId],
          limit: 1,
        );
        if (rows.isEmpty || rows.first['status'] != 'ACTIVE') {
          throw StateError('La reserva ya fue atendida.');
        }
        final quantity = rows.first['quantity'] as int;
        if (status == 'COLLECTED') {
          await transaction.rawUpdate(
            '''
            UPDATE product_variants
            SET physical_stock = physical_stock - ?,
                reserved_stock = reserved_stock - ?
            WHERE id = ? AND physical_stock >= ? AND reserved_stock >= ?
          ''',
            [quantity, quantity, rows.first['variant_id'], quantity, quantity],
          );
        } else {
          await transaction.rawUpdate(
            '''
            UPDATE product_variants
            SET reserved_stock = MAX(0, reserved_stock - ?)
            WHERE id = ?
          ''',
            [quantity, rows.first['variant_id']],
          );
        }
        await transaction.update(
          'store_reservations',
          {'status': status},
          where: 'id = ?',
          whereArgs: [reservationId],
        );
      });
}
