import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/mock_data.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_storage.dart';
import '../features/cart/data/cart_repository.dart';
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
  final _favorites = <int>[1, 3, 4];
  final _cart = <CartItem>[];
  final _orders = <ShopOrder>[];
  final CatalogRepository? catalogRepository;
  final AuthRepository? authRepository;
  final SessionStorage _sessionStorage;
  final CartRepository? cartRepository;
  AuthSession? _authSession;
  List<Product> _remoteProducts = const [];
  bool _catalogLoading = false;
  String? _catalogError;
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
      List.unmodifiable(_walletMovements);
  double get walletBalance =>
      _walletMovements.fold(0, (sum, movement) => sum + movement.amount);

  /// Puntos acumulados en toda la cuenta: 1 punto por cada S/ 1 comprado.
  int get lifetimePoints =>
      _orders.fold(0, (sum, order) => sum + order.total.floor()) +
      _bonusPoints;
  int get points => lifetimePoints - _redeemedPoints;
  MembershipLevel get membership => MembershipLevel.forPoints(lifetimePoints);
  List<int> get favorites => List.unmodifiable(_favorites);
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
    catalog.clear();
    notifyListeners();
  }

  void updateUser(AppUser value) {
    user = value;
    notifyListeners();
  }

  void toggleFavorite(int id) {
    _favorites.contains(id) ? _favorites.remove(id) : _favorites.add(id);
    notifyListeners();
  }

  /// Canjea los puntos disponibles en bloques de [pointsPerRedemption]
  /// y devuelve el saldo agregado al monedero.
  double redeemPoints() {
    final blocks = points ~/ pointsPerRedemption;
    if (blocks == 0) {
      throw StateError('Necesitas al menos $pointsPerRedemption puntos');
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

  void registerRecycling() {
    _bonusPoints += recyclingBonus;
    notifyListeners();
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
    unawaited(
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
    unawaited(
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
    unawaited(
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
      unawaited(_clearRemoteCart(remoteItemIds));
    }
    return order;
  }

  void advanceOrder(ShopOrder order) {
    if (order.status != OrderStatus.delivered) {
      order.status = OrderStatus.values[order.status.index + 1];
      notifyListeners();
    }
  }

  void deliverOrder(ShopOrder order) {
    order.status = OrderStatus.delivered;
    notifyListeners();
  }
}

class ShopScope extends InheritedNotifier<ShopState> {
  const ShopScope({super.key, required ShopState state, required super.child})
    : super(notifier: state);
  static ShopState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShopScope>()!.notifier!;
}
