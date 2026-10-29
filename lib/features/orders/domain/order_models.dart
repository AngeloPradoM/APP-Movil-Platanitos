import '../../catalog/domain/product_models.dart';
import '../../cart/domain/cart_models.dart';
import '../../addresses/domain/address_models.dart';

enum PaymentMethod { wallet, card, cash }

extension PaymentLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.wallet => 'Yape / Plin',
    PaymentMethod.card => 'Tarjeta de Crédito / Débito',
    PaymentMethod.cash => 'Pago en Efectivo (Agentes)',
  };
  String get shortLabel => switch (this) {
    PaymentMethod.wallet => 'Yape / Plin',
    PaymentMethod.card => 'Tarjeta',
    PaymentMethod.cash => 'Efectivo',
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
  String get sizeText => sizeDescription(size, system);
  double get subtotal => product.price * quantity;
}

/// Dirección escrita por el usuario. [id] es el UUID del backend o un
/// identificador `local-…` cuando se guardó sin sesión.
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
    this.carrier,
    this.trackingCode,
    this.paymentStatus,
  });
  final String id;
  final List<OrderItem> items;
  final PaymentMethod payment;
  final DateTime createdAt;
  final double shipping;
  final ShippingAddress? address;

  /// Indica que el pedido existe en el backend y su estado se sincroniza.
  final bool remote;
  final String? carrier;
  final String? trackingCode;
  final String? paymentStatus;
  OrderStatus status;
  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal + shipping;
  String get estimate {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final start = createdAt.add(const Duration(days: 6));
    final end = start.add(const Duration(days: 2));
    final endMonth = months[end.month - 1];
    return start.month == end.month
        ? '${start.day}-${end.day} de $endMonth'
        : '${start.day} de ${months[start.month - 1]} - ${end.day} de $endMonth';
  }
}
