import 'network/api_client.dart';
import 'api_config.dart';
import '../features/account/data/account_repository.dart';
import '../features/account/data/content_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/data/favorites_repository.dart';
import '../features/orders/data/orders_repository.dart';

class AppDependencies {
  AppDependencies({
    required this.auth,
    required this.catalog,
    required this.cart,
    required this.favorites,
    required this.orders,
    required this.account,
    required this.content,
  });

  factory AppDependencies.local() {
    final client = ApiClient(baseUrl: ApiConfig.baseUrl);
    return AppDependencies(
      auth: AuthRepository(client: client),
      catalog: CatalogRepository(client: client),
      cart: CartRepository(client: client),
      favorites: FavoritesRepository(client: client),
      orders: OrdersRepository(client: client),
      account: AccountRepository(client: client),
      content: ContentRepository(client: client),
    );
  }

  final AuthRepository auth;
  final CatalogRepository catalog;
  final CartRepository cart;
  final FavoritesRepository favorites;
  final OrdersRepository orders;
  final AccountRepository account;
  final ContentRepository content;
}
