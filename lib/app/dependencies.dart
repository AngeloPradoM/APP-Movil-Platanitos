import 'package:flutter/foundation.dart';

import '../core/config/app_environment.dart';
import '../core/database/app_database.dart';
import '../features/gift_cards/data/gift_cards_repository.dart';
import '../core/network/api_client.dart';
import '../core/config/api_config.dart';
import '../features/loyalty/data/loyalty_repository.dart';
import '../features/addresses/data/addresses_repository.dart';
import '../features/content/data/content_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/favorites/data/favorites_repository.dart';
import '../features/orders/data/orders_repository.dart';
import '../features/auth/data/local_auth_repository.dart';
import '../features/auth/domain/repositories/auth_repository_contract.dart';
import '../features/catalog/data/local_catalog_repository.dart';
import '../features/inventory/data/sqlite_inventory_repository.dart';
import '../features/inventory/domain/repositories/inventory_repository.dart';
import '../features/operations/data/memory_demo_operations_repository.dart';
import '../features/operations/data/sqlite_demo_operations_repository.dart';
import '../features/operations/domain/repositories/demo_operations_repository.dart';
import './data/memory_demo_store.dart';

class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.catalog,
    required this.cart,
    required this.favorites,
    required this.orders,
    required this.loyalty,
    required this.giftCards,
    required this.content,
    required this.addresses,
    required this.mode,
    this.demoAuth,
    this.inventory,
    this.operations,
    this._database,
  });

  static Future<AppDependencies> create({AppMode? mode}) async {
    final selectedMode = mode ?? AppEnvironment.mode;
    if (selectedMode == AppMode.demo) return _demo();
    return _remote();
  }

  static AppDependencies _remote() {
    final client = ApiClient(baseUrl: ApiConfig.baseUrl);
    return AppDependencies(
      mode: AppMode.remote,
      auth: AuthRepository(client: client),
      catalog: CatalogRepository(client: client),
      cart: CartRepository(client: client),
      favorites: FavoritesRepository(client: client),
      orders: OrdersRepository(client: client),
      loyalty: LoyaltyRepository(client: client),
      giftCards: GiftCardsRepository(client: client),
      content: ContentRepository(client: client),
      addresses: AddressesRepository(client: client),
    );
  }

  static Future<AppDependencies> _demo() async {
    if (kIsWeb) {
      final store = DemoMemoryStore();
      return AppDependencies(
        mode: AppMode.demo,
        auth: null,
        demoAuth: MemoryDemoAuthRepository(store),
        catalog: MemoryCatalogRepository(store),
        inventory: MemoryInventoryRepository(store),
        operations: MemoryDemoOperationsRepository(store),
        cart: null,
        favorites: null,
        orders: null,
        loyalty: null,
        giftCards: null,
        content: null,
        addresses: null,
      );
    }
    final database = await AppDatabase.open();
    return AppDependencies(
      mode: AppMode.demo,
      database: database,
      auth: null,
      demoAuth: LocalAuthRepository(database),
      catalog: LocalCatalogRepository(database),
      inventory: SqliteInventoryRepository(database),
      operations: SqliteDemoOperationsRepository(database),
      cart: null,
      favorites: null,
      orders: null,
      loyalty: null,
      giftCards: null,
      content: null,
      addresses: null,
    );
  }

  final AppMode mode;
  final RemoteAuthRepository? auth;
  final DemoAuthRepository? demoAuth;
  final CatalogRepositoryContract? catalog;
  final InventoryRepository? inventory;
  final DemoOperationsRepository? operations;
  final CartRepository? cart;
  final FavoritesRepository? favorites;
  final OrdersRepository? orders;
  final LoyaltyRepository? loyalty;
  final GiftCardsRepository? giftCards;
  final ContentRepository? content;
  final AddressesRepository? addresses;
  final AppDatabase? _database;

  Future<void> dispose() async => _database?.close();
}
