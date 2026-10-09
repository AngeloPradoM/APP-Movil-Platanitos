import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';
import 'catalog_repository.dart';

class FavoritesRepository {
  FavoritesRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  Future<List<CatalogProduct>> list({required String accessToken}) async =>
      _parse(await _client.get('/favorites', accessToken: accessToken));

  Future<List<CatalogProduct>> add({
    required String accessToken,
    required String productId,
  }) async => _parse(
    await _client.put(
      '/favorites/${Uri.encodeComponent(productId)}',
      accessToken: accessToken,
    ),
  );

  Future<List<CatalogProduct>> remove({
    required String accessToken,
    required String productId,
  }) async => _parse(
    await _client.delete(
      '/favorites/${Uri.encodeComponent(productId)}',
      accessToken: accessToken,
    ),
  );

  List<CatalogProduct> _parse(dynamic payload) => (payload as List<dynamic>)
      .map(
        (product) =>
            CatalogProduct.fromJson(Map<String, dynamic>.from(product as Map)),
      )
      .toList(growable: false);
}
