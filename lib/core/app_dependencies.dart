import 'network/api_client.dart';
import 'api_config.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/cart/data/cart_repository.dart';
import '../features/catalog/data/catalog_repository.dart';

class AppDependencies {
  AppDependencies({required this.auth, required this.catalog, required this.cart});

  factory AppDependencies.local() {
    final client = ApiClient(baseUrl: ApiConfig.baseUrl);
    return AppDependencies(
      auth: AuthRepository(client: client),
      catalog: CatalogRepository(client: client),
      cart: CartRepository(client: client),
    );
  }

  final AuthRepository auth;
  final CatalogRepository catalog;
  final CartRepository cart;
}
