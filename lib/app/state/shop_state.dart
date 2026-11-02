import '../../features/gift_cards/data/gift_cards_repository.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/network/access_token_store.dart';
import '../../core/network/api_client.dart';
import '../../core/network/live_stream.dart';
import '../data/demo_data.dart';
import '../../features/loyalty/data/loyalty_repository.dart';
import '../../features/addresses/data/addresses_repository.dart';
import '../../features/content/data/content_repository.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/favorites/data/favorites_repository.dart';
import '../../features/catalog/domain/catalog_filter.dart';
import '../../features/catalog/domain/categories.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository_contract.dart';
import '../../features/auth/data/session_storage.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/orders/data/orders_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/operations/domain/operations_models.dart';
import '../../features/operations/domain/repositories/demo_operations_repository.dart';
import '../models/shop_models.dart';

export '../../features/catalog/domain/catalog_filter.dart';
export '../../features/catalog/domain/categories.dart';

part '../../features/auth/presentation/controllers/auth_controller.dart';
part '../../features/cart/presentation/controllers/cart_controller.dart';
part '../../features/catalog/presentation/controllers/catalog_controller.dart';
part '../../features/account/presentation/controllers/account_controller.dart';
part '../../features/loyalty/presentation/controllers/loyalty_controller.dart';
part '../../features/favorites/presentation/controllers/favorites_controller.dart';
part '../../features/addresses/presentation/controllers/addresses_controller.dart';
part '../../features/orders/presentation/controllers/orders_controller.dart';
part '../../features/content/presentation/controllers/content_controller.dart';
part '../../features/gift_cards/presentation/controllers/gift_cards_controller.dart';

/// Productos de una o varias categorías; [offline] indica que son de respaldo.
typedef CategoryProducts = ({List<Product> products, bool offline});

class ShopState extends ChangeNotifier {
  ShopState({
    bool seedHistory = true,
    this.catalogRepository,
    this.authRepository,
    this.cartRepository,
    this.favoritesRepository,
    this.ordersRepository,
    this.loyaltyRepository,
    this.giftCardsRepository,
    this.contentRepository,
    this.addressesRepository,
    this.demoAuthRepository,
    this.inventoryRepository,
    this.operationsRepository,
    this.tokenStore,
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
  final CatalogRepositoryContract? catalogRepository;
  final RemoteAuthRepository? authRepository;
  final DemoAuthRepository? demoAuthRepository;
  final InventoryRepository? inventoryRepository;
  final DemoOperationsRepository? operationsRepository;
  final AccessTokenStore? tokenStore;
  final SessionStorage _sessionStorage;
  final CartRepository? cartRepository;
  final FavoritesRepository? favoritesRepository;
  final OrdersRepository? ordersRepository;
  final LoyaltyRepository? loyaltyRepository;
  final GiftCardsRepository? giftCardsRepository;
  final ContentRepository? contentRepository;
  final AddressesRepository? addressesRepository;
  final _addresses = <ShippingAddress>[];
  int _addressSequence = 0;
  AuthSession? _authSession;
  List<Product> _remoteProducts = const [];
  final _cartProducts = <String, Product>{};
  final _galleries = <String, List<String>>{};
  bool _catalogLoading = false;
  String? _catalogError;
  static const catalogPageSize = 50;
  int _catalogPage = 0, _catalogTotal = 0, _catalogTotalPages = 0;
  int _catalogGeneration = 0;
  bool _catalogMoreFailed = false;
  Future<void>? _catalogMoreRequest, _fullCatalogRequest;
  List<ShopCategory>? _remoteCategories;
  bool _categoriesLoading = false, _categoriesFailed = false;
  final _categoryProducts = <String, List<Product>>{};
  LoyaltySummary? _loyalty;
  List<StoreLocation> _stores = stores;
  List<BlogArticle> _articles = blogArticles;
  final _cartRequests = <Future<void>>{};
  int _pendingCartRequests = 0;
  String? _cartError;
  bool _disposed = false;
  bool highContrast = false;
  int liveRevision = 0;
  StreamSubscription<Map<String, dynamic>>? _liveSub;
  Timer? _livePoll;
  String _liveCursor = '';
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

  /// Catálogo cargado más los productos traídos por categoría.
  Iterable<Product> get _knownProducts => [
    ...catalogProducts,
    for (final list in _categoryProducts.values) ...list,
  ];

  /// Favoritos visibles, incluidos los que no llegaron en la página del catálogo.
  List<Product> get favoriteProducts {
    final visible = <int, Product>{
      for (final product in _knownProducts)
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
  bool get catalogHasMore =>
      _remoteProducts.isNotEmpty && _catalogPage < _catalogTotalPages;
  bool get catalogLoadingMore => _catalogMoreRequest != null;
  bool get catalogMoreFailed => _catalogMoreFailed;
  int get catalogTotal =>
      _remoteProducts.isEmpty ? products.length : _catalogTotal;
  bool get cartSyncing => _pendingCartRequests > 0;
  String? get cartError => _cartError;
  String? get accessToken => _authSession?.accessToken;
  bool get isDemoMode => demoAuthRepository != null;
  bool get _canSyncCart =>
      signedIn && cartRepository != null && accessToken != null;
  String? get _sessionToken => signedIn ? accessToken : null;
  int get cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  double get shipping => _cart.isEmpty ? 0 : 6.9;
  double get total => subtotal + shipping;
  List<ShippingAddress> get addresses => List.unmodifiable(_addresses);
  ShippingAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  void setHighContrast(bool value) {
    if (highContrast == value) return;
    highContrast = value;
    _notifySafely();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopLive();
    super.dispose();
  }

  String _requestErrorMessage(Object error) =>
      error is ApiException && const [400, 409, 422].contains(error.statusCode)
      ? error.message
      : _failureMessage;

  /// Tiendas y blog públicos; si el backend no responde quedan los de ejemplo.
  Product? _productById(int id) {
    for (final product in _knownProducts) {
      if (product.id == id) return product;
    }
    return _favoriteProducts[id];
  }

  /// Canjea los puntos disponibles en bloques de [pointsPerRedemption]
  /// y devuelve el saldo agregado al monedero.
}

class ShopScope extends InheritedNotifier<ShopState> {
  const ShopScope({super.key, required ShopState state, required super.child})
    : super(notifier: state);
  static ShopState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShopScope>()!.notifier!;
}
