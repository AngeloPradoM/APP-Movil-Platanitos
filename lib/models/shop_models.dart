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
    this.slug,
    this.images = const [],
    this.remoteVariantIds = const {},
    this.variantStock = const {},
    this.lowStock = false,
    this.sizeSystem = SizeSystem.eur,
    this.sizes = defaultShoeSizes,
    this.availableSizes = const [0, 1, 2, 3, 4, 5],
  });
  final int id;

  /// UUID del backend cuando el producto proviene de PostgreSQL.
  final String? remoteId, slug;

  /// Galería del producto; el listado del backend solo trae la primera foto.
  final List<String> images;

  /// Deben coincidir con IMAGE_VIEWS de backend/database/catalog.
  static const _unsplashViews = [
    '&flip=h',
    '&crop=focalpoint&fp-x=0.42&fp-y=0.55&fp-z=1.8',
    '&crop=focalpoint&fp-x=0.6&fp-y=0.45&fp-z=2.3',
  ];
  List<String> get gallery {
    if (images.length > 1) return images;
    final main = images.isEmpty ? image : images.first;
    if (!main.contains('images.unsplash.com/') || !main.contains('?')) {
      return [main];
    }
    return [main, for (final view in _unsplashViews) '$main$view'];
  }

  /// Claves: índice de talla en [sizes].
  final Map<int, String> remoteVariantIds;
  final Map<int, int> variantStock;
  final String brand, name, category, image, color;
  final double price, oldPrice;
  final bool lowStock;
  final SizeSystem sizeSystem;

  /// Tallas en el sistema propio del producto (EUR, S/M/L, Única…).
  final List<String> sizes;
  final List<int> availableSizes;
  bool get onSale => oldPrice > price;
  int get discount => onSale ? ((1 - price / oldPrice) * 100).round() : 0;

  /// Solo el calzado con tallas EUR conocidas se puede ver en US y CM.
  bool get convertible =>
      sizeSystem == SizeSystem.eur && sizes.every(shoeSizes.containsKey);
  List<SizeSystem> get sizeSystems => convertible
      ? const [SizeSystem.eur, SizeSystem.us, SizeSystem.cm]
      : [sizeSystem];

  String sizeLabel(int index, [SizeSystem? system]) {
    final value = sizes[index];
    final equivalent = convertible ? shoeSizes[value] : null;
    return switch (system) {
      SizeSystem.us when equivalent != null => equivalent.us,
      SizeSystem.cm when equivalent != null => equivalent.cm,
      _ => value,
    };
  }
}

enum SizeSystem { eur, us, cm, alpha, oneSize }

extension SizeSystemLabel on SizeSystem {
  String get label => switch (this) {
    SizeSystem.eur => 'EUR',
    SizeSystem.us => 'US',
    SizeSystem.cm => 'CM',
    SizeSystem.alpha || SizeSystem.oneSize => '',
  };
}

SizeSystem? sizeSystemFromApi(String value) => switch (value.toUpperCase()) {
  'EUR' => SizeSystem.eur,
  'US' => SizeSystem.us,
  'CM' => SizeSystem.cm,
  'ALPHA' => SizeSystem.alpha,
  'ONE_SIZE' => SizeSystem.oneSize,
  _ => null,
};

String sizeDescription(String size, SizeSystem system) => switch (system) {
  SizeSystem.oneSize => 'Talla única',
  SizeSystem.alpha => 'Talla $size',
  _ => 'Talla $size ${system.label}',
};

const defaultShoeSizes = ['35', '36', '37', '38', '39', '40'];

/// Equivalencias aproximadas de calzado a partir de la talla EUR.
const shoeSizes = <String, ({String us, String cm})>{
  '27': (us: '10', cm: '16.5'),
  '28': (us: '11', cm: '17'),
  '29': (us: '11.5', cm: '18'),
  '30': (us: '12.5', cm: '18.5'),
  '31': (us: '13', cm: '19.5'),
  '32': (us: '1', cm: '20'),
  '33': (us: '2', cm: '20.5'),
  '34': (us: '2.5', cm: '21.5'),
  '35': (us: '5', cm: '22'),
  '36': (us: '6', cm: '23'),
  '37': (us: '7', cm: '23.5'),
  '38': (us: '8', cm: '24.5'),
  '39': (us: '9', cm: '25'),
  '40': (us: '10', cm: '26'),
  '41': (us: '11', cm: '26.5'),
  '42': (us: '12', cm: '27'),
  '43': (us: '13', cm: '28'),
  '44': (us: '14', cm: '28.5'),
};

const _alphaOrder = ['XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'];

/// Ordena tallas de cualquier sistema: letras, meses (0-3M) y números.
int compareSizes(String a, String b) {
  double rank(String value) {
    final upper = value.toUpperCase();
    final letter = _alphaOrder.indexOf(upper);
    if (letter >= 0) return letter.toDouble();
    final number = double.tryParse(
      RegExp(r'^\d+(\.\d+)?').firstMatch(value)?.group(0) ?? '',
    );
    if (number == null) return 10000;
    return (upper.endsWith('M') ? 100 : 1000) + number;
  }

  final result = rank(a).compareTo(rank(b));
  return result != 0 ? result : a.compareTo(b);
}

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
  String get size => product.sizeLabel(sizeIndex, system);
  String get sizeText => sizeDescription(size, system);
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
