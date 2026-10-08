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
    this.lowStock = false,
    this.availableSizes = const [0, 1, 2, 3, 4, 5],
  });
  final int id;
  /// UUID del backend cuando el producto proviene de PostgreSQL.
  final String? remoteId;
  final Map<int, String> remoteVariantIds;
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
  });
  final Product product;
  final int sizeIndex;
  final SizeSystem system;
  int quantity;
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

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.items,
    required this.payment,
    required this.createdAt,
    required this.shipping,
    this.status = OrderStatus.preparation,
  });
  final String id;
  final List<OrderItem> items;
  final PaymentMethod payment;
  final DateTime createdAt;
  final double shipping;
  OrderStatus status;
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal + shipping;
  String get estimate {
    final start = createdAt.add(const Duration(days: 6));
    final end = start.add(const Duration(days: 2));
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')} – ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
  }
}
