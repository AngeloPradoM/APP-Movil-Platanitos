import '../../catalog/domain/product_models.dart';

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
