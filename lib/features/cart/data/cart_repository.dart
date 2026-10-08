import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';

class CartRepository {
  CartRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;
  Future<Map<String, dynamic>> sync({
    required String accessToken,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = await _client.post(
      '/cart/sync',
      accessToken: accessToken,
      body: {'items': items},
    );
    return Map<String, dynamic>.from(payload as Map);
  }
}
