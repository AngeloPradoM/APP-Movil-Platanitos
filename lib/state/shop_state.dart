import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/catalog_repository.dart';
import '../data/auth_repository.dart';
import '../data/session_storage.dart';
import '../data/cart_repository.dart';
import '../models/shop_models.dart';

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
  ShopState({bool seedHistory = true, this.catalogRepository, this.authRepository, this.cartRepository, SessionStorage? sessionStorage})
    : _sessionStorage = sessionStorage ?? SessionStorage() {
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
  final catalog = CatalogFilter();
  int _orderSequence = 98240;
  List<int> get favorites => List.unmodifiable(_favorites);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<ShopOrder> get orders => List.unmodifiable(_orders);
  List<Product> get catalogProducts => _remoteProducts.isEmpty ? products : List.unmodifiable(_remoteProducts);
  bool get catalogLoading => _catalogLoading;
  String? get catalogError => _catalogError;
  String? get accessToken => _authSession?.accessToken;
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  double get shipping => _cart.isEmpty ? 0 : 6.9;
  double get total => subtotal + shipping;
  void login({AppUser? account}) {
    user = account ?? user;
    signedIn = true;
    notifyListeners();
  }

  Future<void> loginRemote({required String email, required String password}) async {
    final repository = authRepository;
    if (repository == null) throw StateError('Autenticación remota no configurada');
    final session = await repository.login(email: email, password: password);
    _authSession = session;
    await _sessionStorage.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
    await syncCartRemote();
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

  Future<void> registerRemote({required String email, required String name, required String password, String? phone, String? documentType, String? documentNumber}) async {
    final repository = authRepository;
    if (repository == null) throw StateError('Autenticación remota no configurada');
    final session = await repository.register(
      email: email,
      name: name,
      password: password,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
    );
    _authSession = session;
    await _sessionStorage.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
    await syncCartRemote();
    user = AppUser(
      name: session.user['name'] as String? ?? name,
      document: '${session.user['documentType'] ?? documentType ?? ''} ${session.user['documentNumber'] ?? documentNumber ?? ''}'.trim(),
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
      await _sessionStorage.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
      await syncCartRemote();
      notifyListeners();
    } catch (_) {
      await _sessionStorage.clear();
    }
  }

  Future<void> syncCartRemote() async {
    final repository = cartRepository;
    final token = accessToken;
    if (repository == null || token == null) return;
    final items = _cart
        .where((item) => item.remoteVariantId != null)
        .map((item) => {'variantId': item.remoteVariantId, 'quantity': item.quantity})
        .toList(growable: false);
    if (items.isEmpty) return;
    await repository.sync(accessToken: token, items: items);
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

  void updateCatalog() => notifyListeners();

  Future<void> loadRemoteCatalog() async {
    if (catalogRepository == null || _catalogLoading) return;
    _catalogLoading = true;
    _catalogError = null;
    notifyListeners();
    try {
      final page = await catalogRepository!.listProducts();
      _remoteProducts = page.products.map((product) => product.toShopProduct()).toList(growable: false);
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
    if (index >= 0) {
      _cart[index].quantity++;
    } else {
      _cart.add(
        CartItem(product: product, sizeIndex: sizeIndex, system: system),
      );
    }
    notifyListeners();
  }

  void changeQuantity(CartItem item, int delta) {
    if (!_cart.contains(item)) return;
    item.quantity += delta;
    if (item.quantity <= 0) _cart.remove(item);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _cart.remove(item);
    notifyListeners();
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
    _orders.insert(0, order);
    _cart.clear();
    notifyListeners();
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
