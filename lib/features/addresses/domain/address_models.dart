class ShippingAddress {
  const ShippingAddress({
    this.id,
    required this.label,
    required this.recipient,
    required this.line1,
    required this.district,
    required this.province,
    required this.department,
    this.reference = '',
    this.phone = '',
    this.isDefault = false,
  });
  final String? id;
  final String label, recipient, line1, district, province, department;
  final String reference, phone;
  final bool isDefault;

  bool get isRemote => id != null && !id!.startsWith('local-');
  String get region => '$district, $province, $department';

  ShippingAddress copyWith({String? id, bool? isDefault}) => ShippingAddress(
    id: id ?? this.id,
    label: label,
    recipient: recipient,
    line1: line1,
    district: district,
    province: province,
    department: department,
    reference: reference,
    phone: phone,
    isDefault: isDefault ?? this.isDefault,
  );
}
