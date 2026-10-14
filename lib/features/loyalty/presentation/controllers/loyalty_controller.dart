part of '../../../../app/state/shop_state.dart';

extension LoyaltyController on ShopState {
  Future<void> _refreshLoyalty([String? token]) async {
    final repository = loyaltyRepository;
    final sessionToken = token ?? _sessionToken;
    if (repository == null || sessionToken == null) return;
    await _keepLocalOnFailure(() async {
      _loyalty = await repository.getLoyalty(accessToken: sessionToken);
      _notifySafely();
    });
  }

  Future<double> redeemPoints() async {
    final blocks = points ~/ ShopState.pointsPerRedemption;
    if (blocks == 0) {
      throw StateError(
        'Necesitas al menos ${ShopState.pointsPerRedemption} puntos',
      );
    }
    final repository = loyaltyRepository;
    final token = _sessionToken;
    if (repository != null && token != null) {
      final before = walletBalance;
      try {
        _loyalty = await repository.redeemPoints(accessToken: token);
      } catch (error) {
        throw StateError(_requestErrorMessage(error));
      }
      _notifySafely();
      return walletBalance - before;
    }
    final redeemed = blocks * ShopState.pointsPerRedemption;
    final amount = blocks * ShopState.redemptionValue;
    _redeemedPoints += redeemed;
    _walletMovements.insert(
      0,
      WalletMovement(
        description: 'Canje de $redeemed puntos',
        amount: amount,
        date: DateTime.now(),
      ),
    );
    _notifySafely();
    return amount;
  }

  /// Registra la entrega de calzado usado y devuelve el código Resikla.
  Future<String> registerRecycling() async {
    final repository = loyaltyRepository;
    final token = _sessionToken;
    if (repository == null || token == null) {
      _bonusPoints += ShopState.recyclingBonus;
      _notifySafely();
      return 'RSK-${math.Random().nextInt(900000) + 100000}';
    }
    try {
      final result = await repository.registerRecycling(accessToken: token);
      _loyalty = result.summary;
      _notifySafely();
      return result.code;
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
  }

  /// Emite una eGift Card (sin cobro real) y devuelve su código.
}
