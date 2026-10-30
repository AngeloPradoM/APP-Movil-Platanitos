import '../auth_session.dart';
import '../user_models.dart';

abstract interface class RemoteAuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register({
    required String email,
    required String name,
    required String password,
    String? phone,
    String? documentType,
    String? documentNumber,
  });
  Future<AuthSession> refresh(String refreshToken);
  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? name,
    String? email,
    String? phone,
  });
  Future<void> logout(String refreshToken);
}

abstract interface class DemoAuthRepository {
  Future<List<AppUser>> profiles();
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn(String profileId);
  Future<void> signOut();
}
