import '../inventory_models.dart';

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> list({
    String query = '',
    bool lowStockOnly = false,
  });
  Future<List<StockMovement>> movements({String? variantId, int limit = 50});
  Future<void> registerMovement({
    required String variantId,
    required StockMovementType type,
    required int quantity,
    required String reason,
    required String responsibleUserId,
  });
  Future<void> updatePrice({
    required String variantId,
    required double price,
  });
}
