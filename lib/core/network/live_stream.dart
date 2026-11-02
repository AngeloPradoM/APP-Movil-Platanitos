import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Escucha el canal SSE del backend y se reconecta si la conexión se corta.
class LiveStream {
  LiveStream(this.baseUrl);
  final String baseUrl;

  Stream<Map<String, dynamic>> listen(String token) {
    final controller = StreamController<Map<String, dynamic>>();
    final client = http.Client();
    var closed = false;
    controller.onCancel = () {
      closed = true;
      client.close();
    };
    unawaited(_run(controller, client, token, () => closed));
    return controller.stream;
  }

  Future<void> _run(
    StreamController<Map<String, dynamic>> controller,
    http.Client client,
    String token,
    bool Function() closed,
  ) async {
    while (!closed() && !controller.isClosed) {
      try {
        final request = http.Request('GET', Uri.parse('$baseUrl/live/stream'));
        request.headers['Authorization'] = 'Bearer $token';
        request.headers['Accept'] = 'text/event-stream';
        final response = await client.send(request);
        if (response.statusCode != 200) {
          await Future<void>.delayed(const Duration(seconds: 3));
          continue;
        }
        var buffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          if (closed()) break;
          buffer += chunk;
          final parts = buffer.split('\n\n');
          buffer = parts.removeLast();
          for (final part in parts) {
            final data = part
                .split('\n')
                .where((line) => line.startsWith('data:'))
                .map((line) => line.substring(5).trimLeft())
                .join('\n');
            if (data.isEmpty) continue;
            final decoded = jsonDecode(data);
            if (decoded is Map<String, dynamic> && !controller.isClosed) {
              controller.add(decoded);
            }
          }
        }
      } catch (_) {
        if (!closed()) await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
    await controller.close();
  }
}
