part of '../../../../app/state/shop_state.dart';

extension CartController on ShopState {
  Future<void> loadRemoteCart() async {
    final repository = cartRepository;
    final token = accessToken;
    if (repository == null || token == null) return;
    if (_remoteProducts.isEmpty) await loadRemoteCatalog();
    _beginCartRequest();
    try {
      var remote = await repository.getCart(accessToken: token);
      final pending = _pendingLocalQuantities(remote);
      if (pending.isNotEmpty) {
        remote = await repository.sync(
          accessToken: token,
          items: [
            for (final entry in pending.entries)
              {'variantId': entry.key, 'quantity': entry.value},
          ],
        );
      }
      await _loadCartProducts(remote);
      _applyRemoteCart(remote);
    } catch (error) {
      _cartError = _cartErrorMessage(error);
    } finally {
      _endCartRequest();
    }
  }

  Map<String, int> _pendingLocalQuantities(RemoteCart remote) {
    final remoteByVariant = {
      for (final item in remote.items) item.variantId: item,
    };
    final local = <String, int>{};
    final stockByVariant = <String, int>{};
    for (final item in _cart) {
      final variantId = item.remoteVariantId;
      if (variantId == null || item.remoteItemId != null) continue;
      local[variantId] = (local[variantId] ?? 0) + item.quantity;
      final stock =
          remoteByVariant[variantId]?.stock ??
          item.product.variantStock[item.sizeIndex];
      if (stock != null) stockByVariant[variantId] = stock;
    }
    final pending = <String, int>{};
    for (final entry in local.entries) {
      final alreadyRemote = remoteByVariant[entry.key]?.quantity ?? 0;
      final stock = stockByVariant[entry.key];
      final allowed = stock == null
          ? entry.value
          : math.min(entry.value, stock - alreadyRemote);
      final quantity = math.min(allowed, 20);
      if (quantity > 0) pending[entry.key] = quantity;
    }
    return pending;
  }

  void _applyRemoteCart(RemoteCart remote) {
    final systems = {
      for (final item in _cart)
        if (item.remoteVariantId != null) item.remoteVariantId!: item.system,
    };
    _cart.removeWhere((item) => item.remoteVariantId != null);
    for (final remoteItem in remote.items) {
      final match = _findRemoteVariant(remoteItem.variantId);
      final product = match?.product ?? _productFromCart(remoteItem);
      _cart.add(
        CartItem(
          product: product,
          sizeIndex: match?.sizeIndex ?? 0,
          system: systems[remoteItem.variantId] ?? product.sizeSystem,
          quantity: remoteItem.quantity,
          remoteItemId: remoteItem.id,
        ),
      );
    }
  }

  /// Trae la ficha de los productos de la bolsa que aún no llegaron en las
  /// páginas cargadas del catálogo, para mostrar su imagen y sus tallas.
  Future<void> _loadCartProducts(RemoteCart remote) async {
    final repository = catalogRepository;
    if (repository == null) return;
    final slugs = {
      for (final item in remote.items)
        if (_findRemoteVariant(item.variantId) == null) item.productSlug,
    };
    await Future.wait(
      slugs.map(
        (slug) => _keepLocalOnFailure(() async {
          _cartProducts[slug] = (await repository.getProduct(slug))
              .toShopProduct();
        }),
      ),
    );
  }

  /// Galería completa del producto: el listado solo trae la primera foto y la
  /// ficha del backend trae todas. Si falla, se queda con lo que ya tiene.
  Product _productFromCart(RemoteCartItem item) => Product(
    id: catalogLocalId(item.productSlug),
    remoteVariantIds: {0: item.variantId},
    variantStock: {0: item.stock},
    brand: '',
    name: item.productName,
    category: '',
    price: item.price,
    oldPrice: item.price,
    image: '',
    color: item.color,
    lowStock: item.stock > 0 && item.stock <= 3,
    sizeSystem: sizeSystemFromApi(item.sizeSystem) ?? SizeSystem.eur,
    sizes: [item.sizeValue],
    availableSizes: item.stock > 0 ? const [0] : const [],
  );

  Future<void> _runCartRequest(
    Future<RemoteCart> Function(CartRepository repository, String token)
    request, {
    required VoidCallback revert,
  }) async {
    final repository = cartRepository;
    final token = accessToken;
    if (repository == null || token == null) return;
    _beginCartRequest();
    try {
      _applyRemoteCart(await request(repository, token));
    } catch (error) {
      revert();
      _cartError = _cartErrorMessage(error);
    } finally {
      _endCartRequest();
    }
  }

  Future<void> _clearRemoteCart(List<String> itemIds) async {
    final repository = cartRepository;
    final token = accessToken;
    if (repository == null || token == null) return;
    _beginCartRequest();
    try {
      for (final itemId in itemIds) {
        await repository.removeItem(accessToken: token, itemId: itemId);
      }
    } catch (error) {
      _cartError = _cartErrorMessage(error);
    } finally {
      _endCartRequest();
    }
  }

  void _beginCartRequest() {
    _pendingCartRequests++;
    _cartError = null;
    _notifySafely();
  }

  void _endCartRequest() {
    _pendingCartRequests--;
    _notifySafely();
  }

  String _cartErrorMessage(Object error) {
    if (error is ApiException &&
        error.statusCode == 400 &&
        error.message.toLowerCase().contains('stock')) {
      return ShopState._stockMessage;
    }
    return ShopState._failureMessage;
  }

  void clearCartError() {
    if (_cartError == null) return;
    _cartError = null;
    _notifySafely();
  }

  void _trackCartRequest(Future<void> request) {
    _cartRequests.add(request);
    unawaited(request.whenComplete(() => _cartRequests.remove(request)));
  }

  /// Carga favoritos, pedidos y puntos de la cuenta. Si una consulta falla
  /// se conservan los datos locales para no bloquear el inicio de sesión.
  void addToCart(Product product, int sizeIndex, SizeSystem system) {
    if (sizeIndex < 0 ||
        sizeIndex >= product.sizes.length ||
        !product.availableSizes.contains(sizeIndex)) {
      throw ArgumentError('Selecciona una talla válida');
    }
    if (!product.sizeSystems.contains(system)) system = product.sizeSystem;
    final variantId = product.remoteVariantIds[sizeIndex];
    final index = _cart.indexWhere(
      (item) =>
          item.product.id == product.id &&
          (variantId == null
              ? item.sizeIndex == sizeIndex
              : item.remoteVariantId == variantId),
    );
    final stock = product.variantStock[sizeIndex];
    final current = index >= 0 ? _cart[index].quantity : 0;
    if (stock != null && current + 1 > stock) {
      throw ArgumentError(ShopState._stockMessage);
    }
    final CartItem item;
    if (index >= 0) {
      item = _cart[index];
      item.quantity++;
    } else {
      item = CartItem(product: product, sizeIndex: sizeIndex, system: system);
      _cart.add(item);
    }
    _notifySafely();
    _persistDemoCartItem(item);
    if (variantId == null || !_canSyncCart) return;
    _trackCartRequest(
      _runCartRequest(
        (repository, token) =>
            repository.addItem(accessToken: token, variantId: variantId),
        revert: () {
          if (index >= 0) {
            item.quantity--;
          } else {
            _cart.remove(item);
          }
        },
      ),
    );
  }

  void changeQuantity(CartItem item, int delta) {
    if (!_cart.contains(item)) return;
    final previous = item.quantity;
    final stock = item.product.variantStock[item.sizeIndex];
    if (delta > 0 && stock != null && previous + delta > stock) {
      _cartError = ShopState._stockMessage;
      _notifySafely();
      return;
    }
    final position = _cart.indexOf(item);
    item.quantity += delta;
    if (item.quantity <= 0) _cart.remove(item);
    _notifySafely();
    _persistDemoCartItem(item);
    final itemId = item.remoteItemId;
    if (itemId == null || !_canSyncCart) return;
    final quantity = math.max(item.quantity, 0);
    _trackCartRequest(
      _runCartRequest(
        (repository, token) => repository.updateItem(
          accessToken: token,
          itemId: itemId,
          quantity: quantity,
        ),
        revert: () => _restoreItem(item, previous, position),
      ),
    );
  }

  void removeItem(CartItem item) {
    final position = _cart.indexOf(item);
    if (position < 0) return;
    final previous = item.quantity;
    _cart.remove(item);
    _notifySafely();
    _persistDemoCartItem(item, quantity: 0);
    final itemId = item.remoteItemId;
    if (itemId == null || !_canSyncCart) return;
    _trackCartRequest(
      _runCartRequest(
        (repository, token) =>
            repository.removeItem(accessToken: token, itemId: itemId),
        revert: () => _restoreItem(item, previous, position),
      ),
    );
  }

  void _restoreItem(CartItem item, int quantity, int position) {
    item.quantity = quantity;
    if (!_cart.contains(item)) {
      _cart.insert(math.min(position, _cart.length), item);
    }
  }

  void _persistDemoCartItem(CartItem item, {int? quantity}) {
    final repository = operationsRepository;
    final userId = user.id;
    final variantId = item.remoteVariantId;
    if (!signedIn ||
        repository == null ||
        userId == null ||
        variantId == null) {
      return;
    }
    unawaited(
      repository
          .setCartItem(
            userId,
            variantId,
            quantity ?? math.max(item.quantity, 0),
          )
          .catchError((Object error) {
            _cartError = error is StateError
                ? error.message
                : ShopState._failureMessage;
            _notifySafely();
          }),
    );
  }
}
