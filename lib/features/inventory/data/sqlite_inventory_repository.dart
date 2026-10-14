import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/inventory_models.dart';
import '../domain/repositories/inventory_repository.dart';

class SqliteInventoryRepository implements InventoryRepository {
  SqliteInventoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<InventoryItem>> list({
    String query = '',
    bool lowStockOnly = false,
  }) async {
    final normalized = query.trim().toLowerCase();
    final rows = await _appDatabase.database.rawQuery(
      '''
      SELECT v.id AS variant_id, v.product_id, p.name AS product_name,
             v.size_system, v.size_value, v.color,
             v.physical_stock, v.reserved_stock
      FROM product_variants v
      JOIN products p ON p.id = v.product_id
      WHERE p.active = 1
        AND (? = '' OR LOWER(p.name || ' ' || p.brand || ' ' || v.color || ' ' || v.size_value) LIKE ?)
        AND (? = 0 OR (v.physical_stock - v.reserved_stock) <= 3)
      ORDER BY p.name, CAST(v.size_value AS INTEGER), v.color
    ''',
      [normalized, '%$normalized%', lowStockOnly ? 1 : 0],
    );
    return rows.map(_itemFromRow).toList(growable: false);
  }

  @override
  Future<List<StockMovement>> movements({
    String? variantId,
    int limit = 50,
  }) async {
    final rows = await _appDatabase.database.query(
      'stock_movements',
      where: variantId == null ? null : 'variant_id = ?',
      whereArgs: variantId == null ? null : [variantId],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => StockMovement(
            id: row['id'] as int,
            variantId: row['variant_id'] as String,
            type: StockMovementType.values.byName(row['type'] as String),
            quantity: row['quantity'] as int,
            reason: row['reason'] as String,
            responsibleUserId: row['responsible_user_id'] as String,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> registerMovement({
    required String variantId,
    required StockMovementType type,
    required int quantity,
    required String reason,
    required String responsibleUserId,
  }) async {
    if (quantity < 0 ||
        (quantity == 0 && type != StockMovementType.adjustment)) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    if (reason.trim().isEmpty) throw ArgumentError.value(reason, 'reason');
    await _appDatabase.database.transaction((transaction) async {
      final variants = await transaction.query(
        'product_variants',
        columns: ['physical_stock', 'reserved_stock'],
        where: 'id = ?',
        whereArgs: [variantId],
        limit: 1,
      );
      if (variants.isEmpty) throw StateError('La variante no existe.');
      final current = variants.first['physical_stock'] as int;
      final reserved = variants.first['reserved_stock'] as int;
      final next = switch (type) {
        StockMovementType.entry => current + quantity,
        StockMovementType.exit => current - quantity,
        StockMovementType.adjustment => quantity,
      };
      if (next < reserved) {
        throw StateError(
          'El stock físico no puede ser menor que el reservado.',
        );
      }
      await transaction.update(
        'product_variants',
        {'physical_stock': next},
        where: 'id = ?',
        whereArgs: [variantId],
      );
      await transaction.insert('stock_movements', {
        'variant_id': variantId,
        'type': type.name,
        'quantity': quantity,
        'reason': reason.trim(),
        'responsible_user_id': responsibleUserId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  InventoryItem _itemFromRow(Map<String, Object?> row) => InventoryItem(
    variantId: row['variant_id'] as String,
    productId: row['product_id'] as String,
    productName: row['product_name'] as String,
    sizeSystem: row['size_system'] as String,
    sizeValue: row['size_value'] as String,
    color: row['color'] as String,
    physicalStock: row['physical_stock'] as int,
    reservedStock: row['reserved_stock'] as int,
  );
}
