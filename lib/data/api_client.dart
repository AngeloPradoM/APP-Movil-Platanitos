import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<dynamic> get(String path, {String? accessToken}) async {
    final response = await _client.get(_uri(path), headers: _headers(accessToken));
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body, String? accessToken}) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(accessToken),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers(String? accessToken) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
      };

  dynamic _decode(http.Response response) {
    final payload = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic> ? payload['message']?.toString() : null;
      throw ApiException(response.statusCode, message ?? 'Error de comunicación con el servidor');
    }
    return payload;
  }
}
