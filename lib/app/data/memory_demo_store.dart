import '../../features/auth/domain/repositories/auth_repository_contract.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/domain/categories.dart';
import '../../features/inventory/domain/inventory_models.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/operations/domain/operations_models.dart';
import '../models/shop_models.dart';
import 'demo_data.dart' as demo;

class DemoMemoryStore {
  DemoMemoryStore() {
    for (final product in demo.products) {
      for (final index in product.availableSizes) {
        stock[variantId(product, index)] = index == 0 ? 2 : 8 + (index % 3);
      }
    }
  }

  AppUser? session;
  final Map<String, int> stock = {};
  final Map<String, int> reservedStock = {};
  final Map<String, Map<String, int>> carts = {};
  final List<DemoOrder> orders = [];
  final Map<String, String> preparationStatus = {};
  final List<DeliveryTask> deliveries = [];
  final Map<String, DeliveryEvidence> deliveryEvidence = {};
  final List<SupportRequestRecord> supportRequests = [];
  final List<StoreReservation> reservations = [];
  final List<String> incidents = [];
  final List<StockMovement> stockMovements = [];
  int movementSequence = 0;
  int sequence = 1000;

  static const profiles = <AppUser>[
    AppUser(
      id: 'demo-cliente',
      name: 'Daniela Rojas',
      document: 'DNI 74281639',
      email: 'cliente@demo.local',
      phone: '+51987654321',
    ),
    AppUser(
      id: 'demo-almacen',
      name: 'Marco Almacén',
      document: 'DEMO ALM-01',
      email: 'almacen@demo.local',
      phone: '+51900000001',
      role: UserRole.almacen,
    ),
    AppUser(
      id: 'demo-repartidor',
      name: 'Luis Repartidor',
      document: 'DEMO REP-01',
      email: 'repartidor@demo.local',
      phone: '+51900000002',
      role: UserRole.repartidor,
    ),
    AppUser(
      id: 'demo-atencion',
      name: 'Ana Atención',
      document: 'DEMO ATC-01',
      email: 'atencion@demo.local',
      phone: '+51900000003',
      role: UserRole.atencionCliente,
    ),
    AppUser(
      id: 'demo-administrador',
      name: 'Rosa Administradora',
      document: 'DEMO ADM-01',
      email: 'admin@demo.local',
      phone: '+51900000004',
      role: UserRole.administrador,
    ),
    AppUser(
      id: 'demo-tienda',
      name: 'Carlos Tienda',
      document: 'DEMO TDA-01',
      email: 'tienda@demo.local',
      phone: '+51900000005',
      role: UserRole.trabajadorTienda,
    ),
  ];

  static String variantId(Product product, int sizeIndex) =>
      'product-${product.id}-${product.sizes[sizeIndex]}-${slugify(product.color)}';
}

class MemoryDemoAuthRepository implements DemoAuthRepository {
  MemoryDemoAuthRepository(this._store);
  final DemoMemoryStore _store;

  @override
  Future<List<AppUser>> profiles() async => DemoMemoryStore.profiles;

  @override
  Future<AppUser?> restoreSession() async => _store.session;

  @override
  Future<AppUser> signIn(String profileId) async {
    final user = DemoMemoryStore.profiles.firstWhere(
      (item) => item.id == profileId,
    );
    _store.session = user;
    return user;
  }

  @override
  Future<void> signOut() async => _store.session = null;
}

class MemoryCatalogRepository implements CatalogRepositoryContract {
  MemoryCatalogRepository(this._store);
  final DemoMemoryStore _store;

  List<CatalogProduct> get _products => [
    for (final product in demo.products)
      CatalogProduct(
        id: 'product-${product.id}',
        name: product.name,
        slug: slugify(product.name),
        description: 'Producto de demostración',
        brand: product.brand,
        category: product.category,
        images: [product.image],
        variants: [
          for (final index in product.availableSizes)
            CatalogVariant(
              id: DemoMemoryStore.variantId(product, index),
              sizeSystem: product.sizeSystem.name.toUpperCase(),
              sizeValue: product.sizes[index],
              color: product.color,
              price: product.price,
              comparePrice: product.oldPrice,
              stock:
                  (_store.stock[DemoMemoryStore.variantId(product, index)] ??
                      0) -
                  (_store.reservedStock[DemoMemoryStore.variantId(
                        product,
                        index,
                      )] ??
                      0),
            ),
        ],
      ),
  ];

  @override
  Future<CatalogPage> listProducts({
    String? query,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final normalized = query?.trim().toLowerCase() ?? '';
    final values = _products
        .where(
          (product) =>
              (normalized.isEmpty ||
                  '${product.brand} ${product.name} ${product.category}'
                      .toLowerCase()
                      .contains(normalized)) &&
              (category == null ||
                  category.isEmpty ||
                  slugify(product.category) == category),
        )
        .toList(growable: false);
    final start = ((page < 1 ? 1 : page) - 1) * limit;
    final end = (start + limit).clamp(0, values.length);
    return CatalogPage(
      products: start >= values.length ? const [] : values.sublist(start, end),
      page: page,
      total: values.length,
      totalPages: values.isEmpty ? 0 : (values.length / limit).ceil(),
    );
  }

  @override
  Future<List<ShopCategory>> listCategories() async => categoriesFromProducts(
    _products.map((product) => product.toShopProduct()),
  );

  @override
  Future<CatalogProduct> getProduct(String slug) async =>
      _products.firstWhere((product) => product.slug == slug);
}

class MemoryInventoryRepository implements InventoryRepository {
  MemoryInventoryRepository(this._store);
  final DemoMemoryStore _store;

  @override
  Future<List<InventoryItem>> list({
    String query = '',
    bool lowStockOnly = false,
  }) async {
    final normalized = query.trim().toLowerCase();
    final values = <InventoryItem>[];
    for (final product in demo.products) {
      for (final index in product.availableSizes) {
        final item = InventoryItem(
          variantId: DemoMemoryStore.variantId(product, index),
          productId: 'product-${product.id}',
          productName: product.name,
          sizeSystem: product.sizeSystem.name.toUpperCase(),
          sizeValue: product.sizes[index],
          color: product.color,
          physicalStock:
              _store.stock[DemoMemoryStore.variantId(product, index)] ?? 0,
          reservedStock:
              _store.reservedStock[DemoMemoryStore.variantId(product, index)] ??
              0,
        );
        final matches =
            normalized.isEmpty ||
            '${item.productName} ${item.color} ${item.sizeValue}'
                .toLowerCase()
                .contains(normalized);
        if (matches && (!lowStockOnly || item.lowStock)) values.add(item);
      }
    }
    return values;
  }

  @override
  Future<List<StockMovement>> movements({
    String? variantId,
    int limit = 50,
  }) async => _store.stockMovements
      .where((movement) => variantId == null || movement.variantId == variantId)
      .take(limit)
      .toList(growable: false);

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
    final current = _store.stock[variantId];
    if (current == null) throw StateError('La variante no existe.');
    final next = switch (type) {
      StockMovementType.entry => current + quantity,
      StockMovementType.exit => current - quantity,
      StockMovementType.adjustment => quantity,
    };
    final reserved = _store.reservedStock[variantId] ?? 0;
    if (next < reserved) {
      throw StateError('El stock físico no puede ser menor que el reservado.');
    }
    _store.stock[variantId] = next;
    _store.stockMovements.insert(
      0,
      StockMovement(
        id: ++_store.movementSequence,
        variantId: variantId,
        type: type,
        quantity: quantity,
        reason: reason.trim(),
        responsibleUserId: responsibleUserId,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updatePrice({
    required String variantId,
    required double price,
  }) async {
    throw StateError('El precio de demostración no se edita en memoria.');
  }
}
