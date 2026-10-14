import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class AdministrationRepository {
  AdministrationRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;
  Future<List<dynamic>> users({required String accessToken}) async =>
      List<dynamic>.from(
        await _client.get('/admin/users', accessToken: accessToken) as List,
      );
}
