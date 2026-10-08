import '../data/api_client.dart';
import 'api_config.dart';
import '../data/auth_repository.dart';
import '../data/cart_repository.dart';
import '../data/catalog_repository.dart';

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
