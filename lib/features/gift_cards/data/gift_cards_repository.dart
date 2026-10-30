import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';

class GiftCardsRepository {
  GiftCardsRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  /// Devuelve el código de la eGift Card emitida.
  Future<String> sendGiftCard({
    required String accessToken,
    required int amount,
    required String recipientName,
    required String recipientEmail,
    String? message,
  }) async {
    final payload = await _client.post(
      '/gift-cards',
      accessToken: accessToken,
      body: {
        'amount': amount,
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );
    return (payload as Map)['code'] as String;
  }
}
