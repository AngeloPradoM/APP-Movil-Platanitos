import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../app/models/shop_models.dart';

class LoyaltySummary {
  const LoyaltySummary({
    required this.points,
    required this.lifetimePoints,
    required this.walletBalance,
    required this.walletMovements,
  });
  factory LoyaltySummary.fromJson(Map<String, dynamic> json) => LoyaltySummary(
    points: json['points'] as int,
    lifetimePoints: json['lifetimePoints'] as int,
    walletBalance: double.parse(json['walletBalance'] as String),
    walletMovements: [
      for (final raw in json['movements'] as List<dynamic>)
        if (double.parse((raw as Map)['walletAmount'] as String) > 0)
          WalletMovement(
            description: raw['description'] as String,
            amount: double.parse(raw['walletAmount'] as String),
            date: DateTime.parse(raw['createdAt'] as String).toLocal(),
          ),
    ],
  );
  final int points, lifetimePoints;
  final double walletBalance;
  final List<WalletMovement> walletMovements;
}

class LoyaltyRepository {
  LoyaltyRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  Future<LoyaltySummary> getLoyalty({required String accessToken}) async =>
      _summary(await _client.get('/loyalty', accessToken: accessToken));

  Future<LoyaltySummary> redeemPoints({required String accessToken}) async =>
      _summary(await _client.post('/loyalty/redeem', accessToken: accessToken));

  Future<({String code, LoyaltySummary summary})> registerRecycling({
    required String accessToken,
  }) async {
    final payload = Map<String, dynamic>.from(
      await _client.post('/loyalty/recycling', accessToken: accessToken) as Map,
    );
    return (
      code: payload['code'] as String,
      summary: _summary(payload['summary']),
    );
  }

  LoyaltySummary _summary(dynamic payload) =>
      LoyaltySummary.fromJson(Map<String, dynamic>.from(payload as Map));
}
