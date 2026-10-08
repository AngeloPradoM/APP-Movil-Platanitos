import '../core/api_config.dart';
import 'api_client.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.refreshToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: Map<String, dynamic>.from(json['user'] as Map),
      );

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
}

class AuthRepository {
  AuthRepository({ApiClient? client}) : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

  final ApiClient _client;

  Future<AuthSession> login({required String email, required String password}) async {
    final payload = await _client.post('/auth/login', body: {'email': email, 'password': password});
    return AuthSession.fromJson(payload as Map<String, dynamic>);
  }

  Future<AuthSession> register({required String email, required String name, required String password, String? phone, String? documentType, String? documentNumber}) async {
    final payload = await _client.post('/auth/register', body: {
      'email': email,
      'name': name,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (documentType != null && documentType.isNotEmpty) 'documentType': documentType,
      if (documentNumber != null && documentNumber.isNotEmpty) 'documentNumber': documentNumber,
    });
    return AuthSession.fromJson(payload as Map<String, dynamic>);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final payload = await _client.post('/auth/refresh', body: {'refreshToken': refreshToken});
    return AuthSession.fromJson(payload as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _client.post('/auth/logout', body: {'refreshToken': refreshToken});
  }
}
