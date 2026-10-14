enum StockMovementType { entry, exit, adjustment }

extension StockMovementTypeLabel on StockMovementType {
  String get label => switch (this) {
    StockMovementType.entry => 'Entrada',
    StockMovementType.exit => 'Salida',
    StockMovementType.adjustment => 'Ajuste',
  };
}

class InventoryItem {
  const InventoryItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.sizeSystem,
    required this.sizeValue,
    required this.color,
    required this.physicalStock,
    required this.reservedStock,
  });

  final String variantId;
  final String productId;
  final String productName;
  final String sizeSystem;
  final String sizeValue;
  final String color;
  final int physicalStock;
  final int reservedStock;

  int get availableStock => physicalStock - reservedStock;
  bool get lowStock => availableStock <= 3;
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.variantId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.responsibleUserId,
    required this.createdAt,
  });

  final int id;
  final String variantId;
  final StockMovementType type;
  final int quantity;
  final String reason;
  final String responsibleUserId;
  final DateTime createdAt;
}
