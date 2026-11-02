import 'package:flutter/foundation.dart';

import '../../domain/inventory_models.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryController extends ChangeNotifier {
  InventoryController(this._repository);

  final InventoryRepository _repository;
  List<InventoryItem> _items = const [];
  bool _loading = false;
  bool _lowStockOnly = false;
  String _query = '';
  String? _error;

  List<InventoryItem> get items => _items;
  bool get loading => _loading;
  bool get lowStockOnly => _lowStockOnly;
  String? get error => _error;
  int get availableUnits =>
      _items.fold(0, (sum, item) => sum + item.availableStock);
  int get lowStockCount => _items.where((item) => item.lowStock).length;

  Future<void> load({String? query, bool? lowStockOnly}) async {
    _query = query ?? _query;
    _lowStockOnly = lowStockOnly ?? _lowStockOnly;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _repository.list(
        query: _query,
        lowStockOnly: _lowStockOnly,
      );
    } catch (_) {
      _error = 'No se pudo cargar el inventario.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> registerMovement({
    required InventoryItem item,
    required StockMovementType type,
    required int quantity,
    required String reason,
    required String responsibleUserId,
  }) async {
    await _repository.registerMovement(
      variantId: item.variantId,
      type: type,
      quantity: quantity,
      reason: reason,
      responsibleUserId: responsibleUserId,
    );
    await load();
  }

  Future<void> updatePrice(InventoryItem item, double price) async {
    await _repository.updatePrice(variantId: item.variantId, price: price);
    await load();
  }

  Future<List<StockMovement>> movements(InventoryItem item) =>
      _repository.movements(variantId: item.variantId);
}
