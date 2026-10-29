part of '../../../../app/state/shop_state.dart';

extension OrdersController on ShopState {
  Future<void> loadDemoCommerce({bool mergeCart = false}) async {
    final repository = operationsRepository;
    final userId = user.id;
    if (repository == null || userId == null || user.role != UserRole.cliente) {
      return;
    }
    if (_remoteProducts.isEmpty) await loadRemoteCatalog();
    final localQuantities = <String, int>{};
    if (mergeCart) {
      for (final item in _cart) {
        var variantId = item.remoteVariantId;
        if (variantId == null) {
          for (final product in _remoteProducts) {
            if (product.id != item.product.id) continue;
            final sizeIndex = product.sizes.indexOf(
              item.product.sizes[item.sizeIndex],
            );
            if (sizeIndex >= 0) variantId = product.remoteVariantIds[sizeIndex];
            break;
          }
        }
        if (variantId != null) {
          localQuantities[variantId] =
              (localQuantities[variantId] ?? 0) + item.quantity;
        }
      }
    }
    for (final line in await repository.loadCart(userId)) {
      localQuantities[line.variantId] =
          (localQuantities[line.variantId] ?? 0) + line.quantity;
    }
    _cart.clear();
    for (final entry in localQuantities.entries) {
      final match = _findRemoteVariant(entry.key);
      if (match == null) continue;
      final stock = match.product.variantStock[match.sizeIndex] ?? entry.value;
      final quantity = math.min(entry.value, stock);
      if (quantity <= 0) continue;
      _cart.add(
        CartItem(
          product: match.product,
          sizeIndex: match.sizeIndex,
          system: match.product.sizeSystem,
          quantity: quantity,
        ),
      );
      await repository.setCartItem(userId, entry.key, quantity);
    }
    final records = await repository.orders(userId: userId);
    _orders
      ..removeWhere((order) => !order.remote)
      ..insertAll(
        0,
        records
            .where((record) => record.status != 'CANCELLED')
            .map(_orderFromDemo),
      );
    _notifySafely();
  }

  ShopOrder _orderFromDemo(DemoOrder order) {
    final payment =
        PaymentMethod.values.asNameMap()[order.paymentMethod.toLowerCase()] ??
        PaymentMethod.wallet;
    final status = switch (order.status) {
      'DISPATCHED' => OrderStatus.dispatch,
      'PICKED_UP' || 'IN_TRANSIT' || 'FAILED' => OrderStatus.transit,
      'DELIVERED' => OrderStatus.delivered,
      _ => OrderStatus.preparation,
    };
    return ShopOrder(
      id: order.publicNumber,
      items: List.unmodifiable(order.items.map(_orderItemFromDemo)),
      payment: payment,
      createdAt: order.createdAt,
      shipping: order.shippingCents / 100,
      status: status,
      address: defaultAddress,
    );
  }

  OrderItem _orderItemFromDemo(DemoOrderLine item) {
    final match = item.variantId == null
        ? null
        : _findRemoteVariant(item.variantId!);
    final system = sizeSystemFromApi(item.sizeSystem) ?? SizeSystem.eur;
    return OrderItem(
      product: Product(
        id: match?.product.id ?? catalogLocalId(item.productName),
        remoteId: match?.product.remoteId,
        brand: item.brand,
        name: item.productName,
        category: match?.product.category ?? '',
        price: item.unitPriceCents / 100,
        oldPrice: math.max(
          match?.product.oldPrice ?? 0,
          item.unitPriceCents / 100,
        ),
        image: item.image,
        color: item.color,
        sizeSystem: system,
        sizes: [item.sizeValue],
        availableSizes: const [],
      ),
      size: item.sizeValue,
      system: system,
      quantity: item.quantity,
    );
  }

  void _applyRemoteOrders(List<RemoteOrder> remote) {
    _orders
      ..clear()
      ..addAll(remote.map(_orderFromRemote).whereType<ShopOrder>());
  }

  ShopOrder? _orderFromRemote(RemoteOrder order) {
    final status = OrderStatus.values.asNameMap()[order.status.toLowerCase()];
    final payment = PaymentMethod.values
        .asNameMap()[order.paymentMethod.toLowerCase()];
    if (status == null || payment == null) return null;
    return ShopOrder(
      id: order.publicNumber,
      items: List.unmodifiable(order.items.map(_orderItemFromRemote)),
      payment: payment,
      createdAt: order.createdAt,
      shipping: order.shipping,
      status: status,
      remote: true,
      address: order.address,
      carrier: order.carrier,
      trackingCode: order.trackingCode,
      paymentStatus: order.paymentStatus,
    );
  }

  OrderItem _orderItemFromRemote(RemoteOrderItem item) {
    final variantId = item.variantId;
    final base = variantId == null
        ? null
        : _findRemoteVariant(variantId)?.product;
    final system = sizeSystemFromApi(item.sizeSystem) ?? SizeSystem.eur;
    return OrderItem(
      product: Product(
        id: base?.id ?? catalogLocalId(item.productSlug ?? item.productName),
        remoteId: base?.remoteId,
        brand: base?.brand ?? '',
        name: item.productName,
        category: base?.category ?? '',
        price: item.unitPrice,
        oldPrice: math.max(base?.oldPrice ?? 0, item.unitPrice),
        image: item.image ?? base?.image ?? '',
        color: item.color,
        sizeSystem: system,
        sizes: [item.sizeValue],
        availableSizes: const [],
      ),
      size: item.sizeValue,
      system: system,
      quantity: item.quantity,
    );
  }

  ShopOrder placeOrder(PaymentMethod payment, {ShippingAddress? address}) {
    if (_cart.isEmpty) throw StateError('La bolsa está vacía');
    final order = ShopOrder(
      id: 'PL-${++_orderSequence}',
      items: List.unmodifiable(_cart.map(OrderItem.fromCart)),
      payment: payment,
      createdAt: DateTime.now(),
      shipping: shipping,
      address: address ?? defaultAddress,
    );
    final remoteItemIds = _cart
        .map((item) => item.remoteItemId)
        .whereType<String>()
        .toList(growable: false);
    _orders.insert(0, order);
    _cart.clear();
    _notifySafely();
    if (remoteItemIds.isNotEmpty && _canSyncCart) {
      _trackCartRequest(_clearRemoteCart(remoteItemIds));
    }
    return order;
  }

  /// Registra el pedido en el backend cuando toda la bolsa viene del
  /// catálogo remoto; los productos de demostración usan [placeOrder].
  Future<ShopOrder> checkout(
    PaymentMethod payment, {
    ShippingAddress? address,
  }) async {
    if (_cart.isEmpty) throw StateError('La bolsa está vacía');
    final demoRepository = operationsRepository;
    final userId = user.id;
    if (demoRepository != null && userId != null) {
      for (final item in _cart) {
        final variantId = item.remoteVariantId;
        if (variantId == null) {
          throw StateError('El producto no tiene una variante local válida.');
        }
        await demoRepository.setCartItem(userId, variantId, item.quantity);
      }
      final destination = address ?? defaultAddress;
      final record = await demoRepository.checkout(
        userId: userId,
        paymentMethod: payment.name.toUpperCase(),
        shippingCents: (shipping * 100).round(),
        address: destination == null
            ? 'Recojo coordinado'
            : '${destination.line1}, ${destination.region}',
      );
      final order = _orderFromDemo(record);
      _orders.insert(0, order);
      _cart.clear();
      _notifySafely();
      unawaited(loadRemoteCatalog());
      return order;
    }
    final repository = ordersRepository;
    final token = _sessionToken;
    if (repository == null ||
        token == null ||
        _cart.any((item) => item.remoteVariantId == null)) {
      return placeOrder(payment, address: address);
    }
    if (address != null && !address.isRemote) {
      final local = address;
      await saveAddress(local);
      address =
          _addresses
              .where(
                (item) =>
                    item.line1 == local.line1 &&
                    item.district == local.district &&
                    item.label == local.label,
              )
              .lastOrNull ??
          defaultAddress;
    }
    while (_cartRequests.isNotEmpty) {
      await Future.wait(_cartRequests.toList());
    }
    if (_cart.any((item) => item.remoteItemId == null)) await loadRemoteCart();
    if (_cart.isEmpty || _cart.any((item) => item.remoteItemId == null)) {
      throw StateError(_cartError ?? ShopState._failureMessage);
    }
    final RemoteOrder remote;
    try {
      remote = await repository.create(
        accessToken: token,
        paymentMethod: payment.name.toUpperCase(),
        addressId: address?.isRemote == true ? address!.id : null,
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
    final order = _orderFromRemote(remote)!;
    _orders.insert(0, order);
    _cart.clear();
    _notifySafely();
    unawaited(loadRemoteCatalog());
    unawaited(_refreshLoyalty());
    return order;
  }

  void advanceOrder(ShopOrder order) {
    if (order.status == OrderStatus.delivered) return;
    _setOrderStatus(order, OrderStatus.values[order.status.index + 1]);
  }

  void deliverOrder(ShopOrder order) =>
      _setOrderStatus(order, OrderStatus.delivered);

  void _setOrderStatus(ShopOrder order, OrderStatus status) {
    final previous = order.status;
    if (previous == status) return;
    order.status = status;
    _notifySafely();
    final repository = ordersRepository;
    final token = _sessionToken;
    if (!order.remote || repository == null || token == null) return;
    unawaited(
      repository
          .updateStatus(
            accessToken: token,
            publicNumber: order.id,
            status: status.name.toUpperCase(),
          )
          .then<void>(
            (_) {},
            onError: (Object _) {
              order.status = previous;
              _notifySafely();
            },
          ),
    );
  }
}
