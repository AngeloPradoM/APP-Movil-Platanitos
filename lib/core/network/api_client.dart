import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/api_exception.dart';
export '../errors/api_exception.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;

  Future<dynamic> get(String path, {String? accessToken}) async {
    final response = await _client.get(
      _uri(path),
      headers: _headers(accessToken),
    );
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

  Future<dynamic> put(String path, {Object? body, String? accessToken}) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(accessToken),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final response = await _client.patch(
      _uri(path),
      headers: _headers(accessToken),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path, {String? accessToken}) async {
    final response = await _client.delete(
      _uri(path),
      headers: _headers(accessToken),
    );
    return _decode(response);
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');
  Map<String, String> _headers(String? accessToken) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (accessToken != null && accessToken.isNotEmpty)
      'Authorization': 'Bearer $accessToken',
  };

  dynamic _decode(http.Response response) {
    final payload = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      throw ApiException(
        response.statusCode,
        message ?? 'Error de comunicación con el servidor',
      );
    }
    return payload;
  }
}
