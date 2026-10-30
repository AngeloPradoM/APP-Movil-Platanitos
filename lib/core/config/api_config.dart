import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000';
  }
}
