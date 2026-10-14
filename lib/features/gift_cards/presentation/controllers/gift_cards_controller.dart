part of '../../../../app/state/shop_state.dart';

extension GiftCardsController on ShopState {
  Future<String> sendGiftCard({
    required double amount,
    required String recipientName,
    required String recipientEmail,
    String message = '',
  }) async {
    final repository = giftCardsRepository;
    final token = _sessionToken;
    if (repository == null || token == null) {
      final random = math.Random();
      String block() => random
          .nextInt(0x10000)
          .toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase();
      return 'GC-${block()}-${block()}';
    }
    try {
      return await repository.sendGiftCard(
        accessToken: token,
        amount: amount.round(),
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        message: message,
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
  }
}
