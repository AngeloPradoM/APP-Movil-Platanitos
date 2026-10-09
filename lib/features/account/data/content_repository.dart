import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/shop_models.dart';

class ContentRepository {
  ContentRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  Future<List<StoreLocation>> listStores() async => [
    for (final raw in await _client.get('/content/stores') as List<dynamic>)
      StoreLocation(
        name: (raw as Map)['name'] as String,
        district: raw['district'] as String,
        address: raw['address'] as String,
        hours: raw['hours'] as String,
      ),
  ];

  Future<List<BlogArticle>> listArticles() async => [
    for (final raw in await _client.get('/content/blog') as List<dynamic>)
      BlogArticle(
        title: (raw as Map)['title'] as String,
        category: raw['category'] as String,
        summary: raw['summary'] as String,
        body: raw['body'] as String,
        image: raw['imageUrl'] as String,
        readMinutes: raw['readMinutes'] as int,
      ),
  ];
}
