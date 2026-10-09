import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStorage {
  SessionStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _accessTokenKey = 'platanitos.access_token';
  static const _refreshTokenKey = 'platanitos.refresh_token';
  final FlutterSecureStorage _storage;
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<({String accessToken, String refreshToken})?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;
    return (accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clear() => _storage.deleteAll();
}
