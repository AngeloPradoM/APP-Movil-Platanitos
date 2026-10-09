class Product {
  const Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.image,
    required this.color,
    this.remoteId,
    this.remoteVariantIds = const {},
    this.variantStock = const {},
    this.lowStock = false,
    this.availableSizes = const [0, 1, 2, 3, 4, 5],
  });
  final int id;

  /// UUID del backend cuando el producto proviene de PostgreSQL.
  final String? remoteId;

  /// Claves: índice de talla en [sizeLabels].
  final Map<int, String> remoteVariantIds;
  final Map<int, int> variantStock;
  final String brand, name, category, image, color;
  final double price, oldPrice;
  final bool lowStock;
  final List<int> availableSizes;
  int get discount => ((1 - price / oldPrice) * 100).round();
}

enum SizeSystem { eur, us, cm }

const sizeLabels = {
  SizeSystem.eur: ['35', '36', '37', '38', '39', '40'],
  SizeSystem.us: ['5', '6', '7', '8', '9', '10'],
  SizeSystem.cm: ['22', '23', '23.5', '24.5', '25', '26'],
};

class CartItem {
  CartItem({
    required this.product,
    required this.sizeIndex,
    required this.system,
    this.quantity = 1,
    this.remoteItemId,
  });
  final Product product;
  final int sizeIndex;
  final SizeSystem system;
  int quantity;
  String? remoteItemId;
  String get size => sizeLabels[system]![sizeIndex];
  String? get remoteVariantId => product.remoteVariantIds[sizeIndex];
  double get subtotal => product.price * quantity;
}

class AppUser {
  const AppUser({
    required this.name,
    required this.document,
    required this.email,
    required this.phone,
  });
  final String name, document, email, phone;
}

enum MembershipLevel {
  classic('Clásica', 0, [
    'Envío estándar a todo el Perú',
    'Ofertas por correo',
  ]),
  silver('Plata', 300, [
    'Envío gratis desde S/ 149',
    'Acceso anticipado a campañas',
    'Doble puntos en tu cumpleaños',
  ]),
  gold('Oro', 1000, [
    'Envío gratis en todas tus compras',
    'Cambios sin costo por 60 días',
    'Atención preferente en tienda',
  ]);

  const MembershipLevel(this.label, this.minPoints, this.benefits);
  final String label;
  final int minPoints;
  final List<String> benefits;

  static MembershipLevel forPoints(int points) =>
      values.lastWhere((level) => points >= level.minPoints);

  MembershipLevel? get next =>
      index + 1 < values.length ? values[index + 1] : null;
}

class WalletMovement {
  const WalletMovement({
    required this.description,
    required this.amount,
    required this.date,
  });
  final String description;
  final double amount;
  final DateTime date;
}

class StoreLocation {
  const StoreLocation({
    required this.name,
    required this.district,
    required this.address,
    required this.hours,
  });
  final String name, district, address, hours;
}

class BlogArticle {
  const BlogArticle({
    required this.title,
    required this.category,
    required this.summary,
    required this.body,
    required this.image,
    required this.readMinutes,
  });
  final String title, category, summary, body, image;
  final int readMinutes;
}

enum PaymentMethod { wallet, card, cash }

extension PaymentLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.wallet => 'Yape / Plin',
    PaymentMethod.card => 'Tarjeta de Crédito / Débito',
    PaymentMethod.cash => 'Pago en Efectivo (Agentes)',
  };
}

enum OrderStatus { preparation, dispatch, transit, delivered }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
    OrderStatus.preparation => 'Preparación',
    OrderStatus.dispatch => 'Despacho',
    OrderStatus.transit => 'En camino',
    OrderStatus.delivered => 'Entregado',
  };
}

class OrderItem {
  OrderItem({
    required this.product,
    required this.size,
    required this.system,
    required this.quantity,
  });
  OrderItem.fromCart(CartItem item)
    : product = item.product,
      size = item.size,
      system = item.system,
      quantity = item.quantity;
  final Product product;
  final String size;
  final SizeSystem system;
  final int quantity;
  double get subtotal => product.price * quantity;
}

/// Dirección escrita por el usuario. [id] es el UUID del backend o un
/// identificador `local-…` cuando se guardó sin sesión.
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

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.items,
    required this.payment,
    required this.createdAt,
    required this.shipping,
    this.status = OrderStatus.preparation,
    this.remote = false,
    this.address,
  });
  final String id;
  final List<OrderItem> items;
  final PaymentMethod payment;
  final DateTime createdAt;
  final double shipping;
  final ShippingAddress? address;

  /// Indica que el pedido existe en el backend y su estado se sincroniza.
  final bool remote;
  OrderStatus status;
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal + shipping;
  String get estimate {
    final start = createdAt.add(const Duration(days: 6));
    final end = start.add(const Duration(days: 2));
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} – ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }
}
