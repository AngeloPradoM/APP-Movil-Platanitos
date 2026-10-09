import '../../../core/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/shop_models.dart';

ShippingAddress addressFromJson(Map<String, dynamic> json) => ShippingAddress(
  id: json['id'] as String?,
  label: json['label'] as String? ?? 'Envío',
  recipient: json['recipient'] as String,
  line1: json['line1'] as String,
  district: json['district'] as String,
  province: json['province'] as String,
  department: json['department'] as String,
  reference: json['reference'] as String? ?? '',
  phone: json['phone'] as String? ?? '',
  isDefault: json['isDefault'] as bool? ?? false,
);

class AddressesRepository {
  AddressesRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);
  final ApiClient _client;

  Future<List<ShippingAddress>> list({required String accessToken}) async =>
      _parse(await _client.get('/addresses', accessToken: accessToken));

  Future<List<ShippingAddress>> create({
    required String accessToken,
    required ShippingAddress address,
  }) async => _parse(
    await _client.post(
      '/addresses',
      accessToken: accessToken,
      body: _body(address),
    ),
  );

  Future<List<ShippingAddress>> update({
    required String accessToken,
    required ShippingAddress address,
  }) async => _parse(
    await _client.put(
      '/addresses/${Uri.encodeComponent(address.id!)}',
      accessToken: accessToken,
      body: _body(address),
    ),
  );

  Future<List<ShippingAddress>> remove({
    required String accessToken,
    required String id,
  }) async => _parse(
    await _client.delete(
      '/addresses/${Uri.encodeComponent(id)}',
      accessToken: accessToken,
    ),
  );

  Map<String, dynamic> _body(ShippingAddress address) => {
    'label': address.label,
    'recipient': address.recipient,
    'line1': address.line1,
    'district': address.district,
    'province': address.province,
    'department': address.department,
    if (address.reference.isNotEmpty) 'reference': address.reference,
    if (address.phone.isNotEmpty) 'phone': address.phone,
    'isDefault': address.isDefault,
  };

  List<ShippingAddress> _parse(dynamic payload) => (payload as List<dynamic>)
      .map((item) => addressFromJson(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}
