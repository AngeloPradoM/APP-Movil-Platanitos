import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';
import '../domain/repositories/auth_repository_contract.dart';

export '../domain/auth_session.dart';

class AuthRepository implements RemoteAuthRepository {
  AuthRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession.fromJson(
    await _client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    ) as Map<String, dynamic>,
  );
  @override
  Future<AuthSession> register({
    required String email,
    required String name,
    required String password,
    String? phone,
    String? documentType,
    String? documentNumber,
  }) async => AuthSession.fromJson(
    await _client.post(
      '/auth/register',
      body: {
        'email': email,
        'name': name,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (documentType != null && documentType.isNotEmpty)
          'documentType': documentType,
        if (documentNumber != null && documentNumber.isNotEmpty)
          'documentNumber': documentNumber,
      },
    ) as Map<String, dynamic>,
  );
  @override
  Future<AuthSession> refresh(String refreshToken) async =>
      AuthSession.fromJson(
        await _client.post(
          '/auth/refresh',
          body: {'refreshToken': refreshToken},
        ) as Map<String, dynamic>,
      );
  @override
  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? name,
    String? email,
    String? phone,
  }) async => Map<String, dynamic>.from(
    await _client.patch(
      '/me',
      accessToken: accessToken,
      body: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    ) as Map,
  );
  @override
  Future<void> logout(String refreshToken) async {
    await _client.post('/auth/logout', body: {'refreshToken': refreshToken});
  }
}
