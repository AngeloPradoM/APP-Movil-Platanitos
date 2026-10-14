import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/app/data/memory_demo_store.dart';
import 'package:platanitos_app/core/database/app_database.dart';
import 'package:platanitos_app/features/operations/data/memory_demo_operations_repository.dart';
import 'package:platanitos_app/features/operations/data/sqlite_demo_operations_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late SqliteDemoOperationsRepository repository;
  const variant = 'product-1-36-blanco';

  setUpAll(sqfliteFfiInit);
  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteDemoOperationsRepository(database);
  });
  tearDown(() => database.close());

  Future<dynamic> checkout() async {
    await repository.setCartItem('demo-cliente', variant, 2);
    return repository.checkout(
      userId: 'demo-cliente',
      paymentMethod: 'WALLET',
      shippingCents: 690,
      address: 'Av. Demo 123, Lima',
    );
  }

  test(
    'checkout reserves stock, records simulated payment and clears cart',
    () async {
      final order = await checkout();

      expect(order.items.single.quantity, 2);
      expect(order.paymentStatus, 'APPROVED_SIMULATED');
      expect(await repository.loadCart('demo-cliente'), isEmpty);
      final stock = await database.database.query(
        'product_variants',
        where: 'id = ?',
        whereArgs: [variant],
      );
      expect(stock.single['reserved_stock'], 2);
      final payments = await database.database.query('simulated_payments');
      expect(payments.single['message'], contains('no se proces'));
    },
  );

  test(
    'preparation, dispatch and delivery follow the required order',
    () async {
      final order = await checkout();
      await repository.startPreparation(order.id, 'demo-almacen');
      await repository.markPrepared(order.id, 'demo-almacen');
      await repository.dispatchOrder(
        order.id,
        'demo-almacen',
        'demo-repartidor',
      );

      final stock = await database.database.query(
        'product_variants',
        where: 'id = ?',
        whereArgs: [variant],
      );
      expect(stock.single['reserved_stock'], 0);
      expect(stock.single['physical_stock'], 6);
      expect(
        () => repository.dispatchOrder(
          order.id,
          'demo-almacen',
          'demo-repartidor',
        ),
        throwsStateError,
      );

      final delivery = (await repository.deliveries('demo-repartidor')).single;
      await repository.updateDelivery(delivery.id, 'PICKED_UP');
      expect((await repository.orders()).single.status, 'IN_TRANSIT');
      await expectLater(
        repository.updateDelivery(delivery.id, 'DELIVERED'),
        throwsStateError,
      );
      await repository.updateDelivery(delivery.id, 'IN_TRANSIT');
      await repository.updateDelivery(delivery.id, 'FAILED');
      expect((await repository.orders()).single.status, 'DELIVERY_FAILED');
      expect((await repository.report()).activeDeliveries, 1);
      await repository.updateDelivery(delivery.id, 'IN_TRANSIT');
      await repository.reportIncident(
        delivery.id,
        'ADDRESS',
        'Referencia incompleta',
      );
      await repository.confirmDelivery(
        deliveryId: delivery.id,
        recipientName: 'María Pérez',
        signatureData: '[[[10.0,10.0],[40.0,40.0]]]',
        photoBytes: Uint8List.fromList([1, 2, 3, 4]),
      );
      expect((await repository.orders()).single.status, 'DELIVERED');
      final evidence = await repository.deliveryEvidence(delivery.id);
      expect(evidence?.recipientName, 'María Pérez');
      expect(evidence?.photoBytes, hasLength(4));
      expect((await repository.report()).deliveredOrders, 1);
    },
  );

  test('support requests are restricted to the order owner', () async {
    final order = await checkout();
    await repository.createSupportRequest(
      orderId: order.id,
      userId: 'demo-cliente',
      type: 'CHANGE',
      reason: 'Necesito otra talla',
    );
    final request = (await repository.supportRequests(userId: 'demo-cliente'))
        .single;
    expect(request.status, 'REGISTERED');
    await repository.updateSupportRequest(request.id, 'IN_REVIEW');
    expect((await repository.supportRequests()).single.status, 'IN_REVIEW');
    expect(
      () => repository.createSupportRequest(
        orderId: order.id,
        userId: 'demo-administrador',
        type: 'CLAIM',
        reason: 'No corresponde',
      ),
      throwsStateError,
    );
  });

  test('store reservation reserves and releases stock', () async {
    await repository.createReservation(
      variantId: variant,
      customerName: 'Cliente tienda',
      quantity: 2,
      workerId: 'demo-tienda',
    );
    final reservation = (await repository.reservations()).single;
    var stock = await database.database.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [variant],
    );
    expect(stock.single['reserved_stock'], 2);

    await repository.updateReservation(reservation.id, 'CANCELLED');
    stock = await database.database.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [variant],
    );
    expect(stock.single['reserved_stock'], 0);
  });

  test('checkout rollback keeps the cart when stock changes', () async {
    await repository.setCartItem('demo-cliente', variant, 2);
    await database.database.update(
      'product_variants',
      {'physical_stock': 1},
      where: 'id = ?',
      whereArgs: [variant],
    );

    expect(
      () => repository.checkout(
        userId: 'demo-cliente',
        paymentMethod: 'WALLET',
        shippingCents: 690,
        address: 'Av. Demo 123, Lima',
      ),
      throwsStateError,
    );
    expect(await repository.loadCart('demo-cliente'), hasLength(1));
    expect(await repository.orders(), isEmpty);
  });

  test('cancelling an order releases its reserved stock', () async {
    final order = await checkout();
    await repository.cancelOrder(order.id, 'demo-cliente');

    final stock = await database.database.query(
      'product_variants',
      where: 'id = ?',
      whereArgs: [variant],
    );
    expect(stock.single['reserved_stock'], 0);
    expect((await repository.orders()).single.status, 'CANCELLED');
  });

  test(
    'collecting a store reservation discounts physical stock once',
    () async {
      await repository.createReservation(
        variantId: variant,
        customerName: 'Cliente tienda',
        quantity: 2,
        workerId: 'demo-tienda',
      );
      final reservation = (await repository.reservations()).single;
      await repository.updateReservation(reservation.id, 'COLLECTED');

      final stock = await database.database.query(
        'product_variants',
        where: 'id = ?',
        whereArgs: [variant],
      );
      expect(stock.single['physical_stock'], 6);
      expect(stock.single['reserved_stock'], 0);
      expect(
        () => repository.updateReservation(reservation.id, 'COLLECTED'),
        throwsStateError,
      );
    },
  );

  test('memory delivery states match the SQLite behavior', () async {
    final store = DemoMemoryStore();
    final memory = MemoryDemoOperationsRepository(store);
    await memory.setCartItem('demo-cliente', variant, 1);
    final order = await memory.checkout(
      userId: 'demo-cliente',
      paymentMethod: 'WALLET',
      shippingCents: 690,
      address: 'Av. Demo 123, Lima',
    );
    await memory.startPreparation(order.id, 'demo-almacen');
    await memory.markPrepared(order.id, 'demo-almacen');
    await memory.dispatchOrder(order.id, 'demo-almacen', 'demo-repartidor');

    final delivery = (await memory.deliveries('demo-repartidor')).single;
    await memory.updateDelivery(delivery.id, 'PICKED_UP');
    expect((await memory.orders()).single.status, 'IN_TRANSIT');
    await memory.updateDelivery(delivery.id, 'IN_TRANSIT');
    await memory.updateDelivery(delivery.id, 'FAILED');
    expect((await memory.orders()).single.status, 'DELIVERY_FAILED');
    expect((await memory.report()).activeDeliveries, 1);
    await expectLater(
      memory.updateDelivery(delivery.id, 'DELIVERED'),
      throwsStateError,
    );
  });
}
