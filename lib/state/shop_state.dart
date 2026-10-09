import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../features/account/data/account_repository.dart';
import '../features/account/data/content_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/data/favorites_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_storage.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../shared/models/shop_models.dart';

enum ProductSort { recommended, cheapest, expensive, recent, offers }

class CatalogFilter {
  String query = '';
  String? brand, color;
  int? sizeIndex;
  double maxPrice = 250;
  ProductSort sort = ProductSort.recommended;
  List<Product> apply(Iterable<Product> source, {List<int>? favorites}) {
    final term = query.trim().toLowerCase();
    final result = source
        .where(
          (p) =>
              '${p.name} ${p.brand} ${p.category}'.toLowerCase().contains(
                term,
              ) &&
              (brand == null || p.brand == brand) &&
              (color == null || p.color == color) &&
              p.price <= maxPrice &&
              (sizeIndex == null || p.availableSizes.contains(sizeIndex)),
        )
        .toList();
    result.sort(
      (a, b) => switch (sort) {
        ProductSort.cheapest => a.price.compareTo(b.price),
        ProductSort.expensive => b.price.compareTo(a.price),
        ProductSort.offers => (b.oldPrice - b.price).compareTo(
          a.oldPrice - a.price,
        ),
        ProductSort.recent => (favorites?.indexOf(b.id) ?? b.id).compareTo(
          favorites?.indexOf(a.id) ?? a.id,
        ),
        ProductSort.recommended => a.id.compareTo(b.id),
      },
    );
    return result;
  }

  void clear() {
    brand = null;
    color = null;
    sizeIndex = null;
    maxPrice = 250;
    query = '';
  }
}

class ShopState extends ChangeNotifier {
  ShopState({
    bool seedHistory = true,
    this.catalogRepository,
    this.authRepository,
    this.cartRepository,
    this.favoritesRepository,
    this.ordersRepository,
    this.accountRepository,
    this.contentRepository,
    SessionStorage? sessionStorage,
  }) : _sessionStorage = sessionStorage ?? SessionStorage() {
    if (seedHistory) {
      _orders.add(
        ShopOrder(
          id: 'PL-87012',
          items: [
            OrderItem.fromCart(
              CartItem(
                product: products[3],
                sizeIndex: 2,
                system: SizeSystem.eur,
              ),
            ),
          ],
          payment: PaymentMethod.wallet,
          createdAt: DateTime(2026, 7, 10),
          shipping: 6.9,
          status: OrderStatus.delivered,
        ),
      );
    }
  }
  AppUser user = demoUser;
  bool signedIn = false;
  static const _demoFavorites = [1, 3, 4];
  final _favorites = <int>[..._demoFavorites];
  final _favoriteProducts = <int, Product>{};
  final _cart = <CartItem>[];
  final _orders = <ShopOrder>[];
  final CatalogRepository? catalogRepository;
  final AuthRepository? authRepository;
  final SessionStorage _sessionStorage;
  final CartRepository? cartRepository;
  final FavoritesRepository? favoritesRepository;
  final OrdersRepository? ordersRepository;
  final AccountRepository? accountRepository;
  final ContentRepository? contentRepository;
  AuthSession? _authSession;
  List<Product> _remoteProducts = const [];
  bool _catalogLoading = false;
  String? _catalogError;
  LoyaltySummary? _loyalty;
  List<StoreLocation> _stores = stores;
  List<BlogArticle> _articles = blogArticles;
  final _cartRequests = <Future<void>>{};
  int _pendingCartRequests = 0;
  String? _cartError;
  bool _disposed = false;
  static const _failureMessage =
      'El sistema está fallando en este momento. Intenta más tarde.';
  static const _stockMessage = 'No hay más stock disponible para esta talla.';
  final catalog = CatalogFilter();
  int _orderSequence = 98240;
  int _bonusPoints = 0;
  int _redeemedPoints = 0;
  final _walletMovements = <WalletMovement>[];
  static const pointsPerRedemption = 100;
  static const redemptionValue = 5.0;
  static const recyclingBonus = 50;
  List<WalletMovement> get walletMovements =>
      List.unmodifiable(_loyalty?.walletMovements ?? _walletMovements);
  double get walletBalance =>
      _loyalty?.walletBalance ??
      _walletMovements.fold(0, (sum, movement) => sum + movement.amount);

  /// Puntos acumulados en toda la cuenta: 1 punto por cada S/ 1 comprado.
  int get lifetimePoints =>
      _loyalty?.lifetimePoints ??
      _orders.fold(0, (sum, order) => sum + order.total.floor()) + _bonusPoints;
  int get points => _loyalty?.points ?? lifetimePoints - _redeemedPoints;
  MembershipLevel get membership => MembershipLevel.forPoints(lifetimePoints);
  List<StoreLocation> get storeLocations => List.unmodifiable(_stores);
  List<BlogArticle> get articles => List.unmodifiable(_articles);
  List<int> get favorites => List.unmodifiable(_favorites);

  /// Favoritos visibles, incluidos los que no llegaron en la página del catálogo.
  List<Product> get favoriteProducts {
    final visible = {
      for (final product in catalogProducts)
        if (_favorites.contains(product.id)) product.id: product,
    };
    for (final entry in _favoriteProducts.entries) {
      if (_favorites.contains(entry.key)) {
        visible.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return List.unmodifiable(visible.values);
  }

  List<CartItem> get cart => List.unmodifiable(_cart);
  List<ShopOrder> get orders => List.unmodifiable(_orders);
  List<Product> get catalogProducts =>
      _remoteProducts.isEmpty ? products : List.unmodifiable(_remoteProducts);
  bool get catalogLoading => _catalogLoading;
  String? get catalogError => _catalogError;
  bool get cartSyncing => _pendingCartRequests > 0;
  String? get cartError => _cartError;
  String? get accessToken => _authSession?.accessToken;
  bool get _canSyncCart =>
      signedIn && cartRepository != null && accessToken != null;
  String? get _sessionToken => signedIn ? accessToken : null;
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  double get shipping => _cart.isEmpty ? 0 : 6.9;
  double get total => subtotal + shipping;
  void login({AppUser? account}) {
    user = account ?? user;
    signedIn = true;
    notifyListeners();
  }

  Future<void> loginRemote({
    required String email,
    required String password,
  }) async {
    final repository = authRepository;
    if (repository == null) {
      throw StateError('Autenticación remota no configurada');
    }
    final session = await repository.login(email: email, password: password);
    _authSession = session;
    await _sessionStorage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await loadRemoteCart();
    await _loadAccountData();
    final remoteUser = session.user;
    user = AppUser(
      name: remoteUser['name'] as String? ?? user.name,
      document: remoteUser['documentNumber'] as String? ?? user.document,
      email: remoteUser['email'] as String? ?? email,
      phone: remoteUser['phone'] as String? ?? user.phone,
    );
    signedIn = true;
    notifyListeners();
  }

  Future<void> registerRemote({
    required String email,
    required String name,
    required String password,
    String? phone,
    String? documentType,
    String? documentNumber,
  }) async {
    final repository = authRepository;
    if (repository == null) {
      throw StateError('Autenticación remota no configurada');
    }
    final session = await repository.register(
      email: email,
      name: name,
      password: password,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
    );
    _authSession = session;
    await _sessionStorage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await loadRemoteCart();
    await _loadAccountData();
    user = AppUser(
      name: session.user['name'] as String? ?? name,
      document:
          '${session.user['documentType'] ?? documentType ?? ''} ${session.user['documentNumber'] ?? documentNumber ?? ''}'
              .trim(),
      email: session.user['email'] as String? ?? email,
      phone: session.user['phone'] as String? ?? phone ?? user.phone,
    );
    signedIn = true;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    if (authRepository == null) return;
    final stored = await _sessionStorage.read();
    if (stored == null) return;
    try {
      final session = await authRepository!.refresh(stored.refreshToken);
      _authSession = session;
      final remoteUser = session.user;
      user = AppUser(
        name: remoteUser['name'] as String? ?? user.name,
        document: remoteUser['documentNumber'] as String? ?? user.document,
        email: remoteUser['email'] as String? ?? user.email,
        phone: remoteUser['phone'] as String? ?? user.phone,
      );
      signedIn = true;
      await _sessionStorage.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await loadRemoteCart();
      await _loadAccountData();
      notifyListeners();
    } catch (_) {
      await _sessionStorage.clear();
    }
  }

  /// Fusiona el carrito local con el guardado en el servidor sumando
  /// cantidades por variante, sin superar el stock disponible.
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
      final sizeIndex =
          match?.sizeIndex ??
          sizeLabels[SizeSystem.eur]!.indexOf(remoteItem.sizeValue);
      if (sizeIndex < 0) continue;
      _cart.add(
        CartItem(
          product: match?.product ?? _productFromCart(remoteItem, sizeIndex),
          sizeIndex: sizeIndex,
          system: systems[remoteItem.variantId] ?? SizeSystem.eur,
          quantity: remoteItem.quantity,
          remoteItemId: remoteItem.id,
        ),
      );
    }
  }

  ({Product product, int sizeIndex})? _findRemoteVariant(String variantId) {
    for (final product in _remoteProducts) {
      for (final entry in product.remoteVariantIds.entries) {
        if (entry.value == variantId) {
          return (product: product, sizeIndex: entry.key);
        }
      }
    }
    return null;
  }

  Product _productFromCart(RemoteCartItem item, int sizeIndex) => Product(
    id: item.productSlug.hashCode,
    remoteVariantIds: {sizeIndex: item.variantId},
    variantStock: {sizeIndex: item.stock},
    brand: '',
    name: item.productName,
    category: '',
    price: item.price,
    oldPrice: item.price,
    image: '',
    color: item.color,
    lowStock: item.stock > 0 && item.stock <= 3,
    availableSizes: item.stock > 0 ? [sizeIndex] : const [],
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
      return _stockMessage;
    }
    return _failureMessage;
  }

  void clearCartError() {
    if (_cartError == null) return;
    _cartError = null;
    notifyListeners();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _trackCartRequest(Future<void> request) {
    _cartRequests.add(request);
    unawaited(request.whenComplete(() => _cartRequests.remove(request)));
  }

  /// Carga favoritos, pedidos y puntos de la cuenta. Si una consulta falla
  /// se conservan los datos locales para no bloquear el inicio de sesión.
  Future<void> _loadAccountData() async {
    final token = accessToken;
    if (token == null) return;
    final favoritesSource = favoritesRepository;
    final ordersSource = ordersRepository;
    await Future.wait([
      if (favoritesSource != null)
        _keepLocalOnFailure(
          () async => _applyRemoteFavorites(
            await favoritesSource.list(accessToken: token),
          ),
        ),
      if (ordersSource != null)
        _keepLocalOnFailure(
          () async =>
              _applyRemoteOrders(await ordersSource.list(accessToken: token)),
        ),
      _refreshLoyalty(token),
    ]);
    _notifySafely();
  }

  Future<void> _keepLocalOnFailure(Future<void> Function() request) async {
    try {
      await request();
    } catch (_) {}
  }

  Future<void> _refreshLoyalty([String? token]) async {
    final repository = accountRepository;
    final sessionToken = token ?? _sessionToken;
    if (repository == null || sessionToken == null) return;
    await _keepLocalOnFailure(() async {
      _loyalty = await repository.getLoyalty(accessToken: sessionToken);
      _notifySafely();
    });
  }

  void _applyRemoteFavorites(List<CatalogProduct> remote) {
    final mapped = remote.map((product) => product.toShopProduct()).toList();
    _favoriteProducts
      ..clear()
      ..addEntries(mapped.map((product) => MapEntry(product.id, product)));
    // El backend devuelve primero el más reciente; localmente va al final.
    _favorites
      ..clear()
      ..addAll(mapped.reversed.map((product) => product.id));
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
    );
  }

  OrderItem _orderItemFromRemote(RemoteOrderItem item) {
    final variantId = item.variantId;
    final base = variantId == null
        ? null
        : _findRemoteVariant(variantId)?.product;
    return OrderItem(
      product: Product(
        id: base?.id ?? (item.productSlug ?? item.productName).hashCode,
        remoteId: base?.remoteId,
        brand: base?.brand ?? '',
        name: item.productName,
        category: base?.category ?? '',
        price: item.unitPrice,
        oldPrice: math.max(base?.oldPrice ?? 0, item.unitPrice),
        image: item.image ?? base?.image ?? '',
        color: item.color,
        availableSizes: const [],
      ),
      size: item.sizeValue,
      system:
          SizeSystem.values.asNameMap()[item.sizeSystem.toLowerCase()] ??
          SizeSystem.eur,
      quantity: item.quantity,
    );
  }

  String _requestErrorMessage(Object error) =>
      error is ApiException && const [400, 409, 422].contains(error.statusCode)
      ? error.message
      : _failureMessage;

  /// Tiendas y blog públicos; si el backend no responde quedan los de ejemplo.
  Future<void> loadContent() async {
    final repository = contentRepository;
    if (repository == null) return;
    await _keepLocalOnFailure(() async {
      final (remoteStores, remoteArticles) = await (
        repository.listStores(),
        repository.listArticles(),
      ).wait;
      if (remoteStores.isNotEmpty) _stores = remoteStores;
      if (remoteArticles.isNotEmpty) _articles = remoteArticles;
      _notifySafely();
    });
  }

  void logout() {
    final refreshToken = _authSession?.refreshToken;
    if (refreshToken != null && authRepository != null) {
      authRepository!.logout(refreshToken).catchError((_) {});
    }
    _authSession = null;
    _sessionStorage.clear();
    signedIn = false;
    _cart.clear();
    _cartError = null;
    _orders.removeWhere((order) => order.remote);
    _favorites
      ..clear()
      ..addAll(_demoFavorites);
    _favoriteProducts.clear();
    _loyalty = null;
    catalog.clear();
    notifyListeners();
  }

  void updateUser(AppUser value) {
    user = value;
    notifyListeners();
  }

  /// Guarda nombre, correo y teléfono en el backend cuando hay sesión.
  Future<void> saveProfile(AppUser value) async {
    final repository = authRepository;
    final token = _sessionToken;
    if (repository == null || token == null) return updateUser(value);
    final Map<String, dynamic> remote;
    try {
      remote = await repository.updateProfile(
        accessToken: token,
        name: value.name,
        email: value.email,
        phone: value.phone,
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
    updateUser(
      AppUser(
        name: remote['name'] as String? ?? value.name,
        document: value.document,
        email: remote['email'] as String? ?? value.email,
        phone: remote['phone'] as String? ?? value.phone,
      ),
    );
  }

  void toggleFavorite(int id) {
    final adding = !_favorites.contains(id);
    adding ? _favorites.add(id) : _favorites.remove(id);
    notifyListeners();
    final repository = favoritesRepository;
    final token = _sessionToken;
    final productId = _productById(id)?.remoteId;
    if (repository == null || token == null || productId == null) return;
    unawaited(() async {
      try {
        _applyRemoteFavorites(
          adding
              ? await repository.add(accessToken: token, productId: productId)
              : await repository.remove(
                  accessToken: token,
                  productId: productId,
                ),
        );
      } catch (_) {
        adding ? _favorites.remove(id) : _favorites.add(id);
      }
      _notifySafely();
    }());
  }

  Product? _productById(int id) {
    for (final product in catalogProducts) {
      if (product.id == id) return product;
    }
    return _favoriteProducts[id];
  }

  /// Canjea los puntos disponibles en bloques de [pointsPerRedemption]
  /// y devuelve el saldo agregado al monedero.
  Future<double> redeemPoints() async {
    final blocks = points ~/ pointsPerRedemption;
    if (blocks == 0) {
      throw StateError('Necesitas al menos $pointsPerRedemption puntos');
    }
    final repository = accountRepository;
    final token = _sessionToken;
    if (repository != null && token != null) {
      final before = walletBalance;
      try {
        _loyalty = await repository.redeemPoints(accessToken: token);
      } catch (error) {
        throw StateError(_requestErrorMessage(error));
      }
      notifyListeners();
      return walletBalance - before;
    }
    final redeemed = blocks * pointsPerRedemption;
    final amount = blocks * redemptionValue;
    _redeemedPoints += redeemed;
    _walletMovements.insert(
      0,
      WalletMovement(
        description: 'Canje de $redeemed puntos',
        amount: amount,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
    return amount;
  }

  /// Registra la entrega de calzado usado y devuelve el código Resikla.
  Future<String> registerRecycling() async {
    final repository = accountRepository;
    final token = _sessionToken;
    if (repository == null || token == null) {
      _bonusPoints += recyclingBonus;
      notifyListeners();
      return 'RSK-${math.Random().nextInt(900000) + 100000}';
    }
    try {
      final result = await repository.registerRecycling(accessToken: token);
      _loyalty = result.summary;
      notifyListeners();
      return result.code;
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
  }

  /// Emite una eGift Card (sin cobro real) y devuelve su código.
  Future<String> sendGiftCard({
    required double amount,
    required String recipientName,
    required String recipientEmail,
    String message = '',
  }) async {
    final repository = accountRepository;
    final token = _sessionToken;
    if (repository == null || token == null) {
      final random = math.Random();
      String block() => random
          .nextInt(0x10000)
          .toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase();
      return 'GC-${block()}-${block()}';
    }
    try {
      return await repository.sendGiftCard(
        accessToken: token,
        amount: amount.round(),
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        message: message,
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
  }

  void updateCatalog() => notifyListeners();

  Future<void> loadRemoteCatalog() async {
    if (catalogRepository == null || _catalogLoading) return;
    _catalogLoading = true;
    _catalogError = null;
    notifyListeners();
    try {
      final page = await catalogRepository!.listProducts();
      _remoteProducts = page.products
          .map((product) => product.toShopProduct())
          .toList(growable: false);
    } catch (error) {
      _catalogError = error.toString();
      _remoteProducts = const [];
    } finally {
      _catalogLoading = false;
      notifyListeners();
    }
  }

  void addToCart(Product product, int sizeIndex, SizeSystem system) {
    if (sizeIndex < 0 ||
        sizeIndex >= sizeLabels[system]!.length ||
        !product.availableSizes.contains(sizeIndex)) {
      throw ArgumentError('Selecciona una talla válida');
    }
    final index = _cart.indexWhere(
      (item) => item.product.id == product.id && item.sizeIndex == sizeIndex,
    );
    final stock = product.variantStock[sizeIndex];
    final current = index >= 0 ? _cart[index].quantity : 0;
    if (stock != null && current + 1 > stock) {
      throw ArgumentError(_stockMessage);
    }
    final CartItem item;
    if (index >= 0) {
      item = _cart[index];
      item.quantity++;
    } else {
      item = CartItem(product: product, sizeIndex: sizeIndex, system: system);
      _cart.add(item);
    }
    notifyListeners();
    final variantId = item.remoteVariantId;
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
      _cartError = _stockMessage;
      notifyListeners();
      return;
    }
    final position = _cart.indexOf(item);
    item.quantity += delta;
    if (item.quantity <= 0) _cart.remove(item);
    notifyListeners();
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
    notifyListeners();
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

  ShopOrder placeOrder(PaymentMethod payment) {
    if (_cart.isEmpty) throw StateError('La bolsa está vacía');
    final order = ShopOrder(
      id: 'PL-${++_orderSequence}',
      items: List.unmodifiable(_cart.map(OrderItem.fromCart)),
      payment: payment,
      createdAt: DateTime.now(),
      shipping: shipping,
    );
    final remoteItemIds = _cart
        .map((item) => item.remoteItemId)
        .whereType<String>()
        .toList(growable: false);
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
    if (remoteItemIds.isNotEmpty && _canSyncCart) {
      _trackCartRequest(_clearRemoteCart(remoteItemIds));
    }
    return order;
  }

  /// Registra el pedido en el backend cuando toda la bolsa viene del
  /// catálogo remoto; los productos de demostración usan [placeOrder].
  Future<ShopOrder> checkout(PaymentMethod payment) async {
    if (_cart.isEmpty) throw StateError('La bolsa está vacía');
    final repository = ordersRepository;
    final token = _sessionToken;
    if (repository == null ||
        token == null ||
        _cart.any((item) => item.remoteVariantId == null)) {
      return placeOrder(payment);
    }
    while (_cartRequests.isNotEmpty) {
      await Future.wait(_cartRequests.toList());
    }
    if (_cart.any((item) => item.remoteItemId == null)) await loadRemoteCart();
    if (_cart.isEmpty || _cart.any((item) => item.remoteItemId == null)) {
      throw StateError(_cartError ?? _failureMessage);
    }
    final RemoteOrder remote;
    try {
      remote = await repository.create(
        accessToken: token,
        paymentMethod: payment.name.toUpperCase(),
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
    final order = _orderFromRemote(remote)!;
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
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
    notifyListeners();
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

class ShopScope extends InheritedNotifier<ShopState> {
  const ShopScope({super.key, required ShopState state, required super.child})
    : super(notifier: state);
  static ShopState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShopScope>()!.notifier!;
}
