import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/core/database/app_database.dart';
import 'package:platanitos_app/features/inventory/data/sqlite_inventory_repository.dart';
import 'package:platanitos_app/features/inventory/domain/inventory_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;
  late SqliteInventoryRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    appDatabase = await AppDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = SqliteInventoryRepository(appDatabase);
  });

  tearDown(() => appDatabase.close());

  test('entry and exit update stock and create an audit trail', () async {
    final item = (await repository.list()).first;

    await repository.registerMovement(
      variantId: item.variantId,
      type: StockMovementType.entry,
      quantity: 5,
      reason: 'Recepción de prueba',
      responsibleUserId: 'demo-almacen',
    );
    await repository.registerMovement(
      variantId: item.variantId,
      type: StockMovementType.exit,
      quantity: 2,
      reason: 'Salida de prueba',
      responsibleUserId: 'demo-almacen',
    );

    final updated = (await repository.list()).firstWhere(
      (value) => value.variantId == item.variantId,
    );
    final movements = await repository.movements(variantId: item.variantId);
    expect(updated.physicalStock, item.physicalStock + 3);
    expect(movements.map((movement) => movement.type), [
      StockMovementType.exit,
      StockMovementType.entry,
    ]);
  });

  test('invalid exit rolls back without writing a movement', () async {
    final item = (await repository.list()).first;

    await expectLater(
      repository.registerMovement(
        variantId: item.variantId,
        type: StockMovementType.exit,
        quantity: item.physicalStock + 1,
        reason: 'Salida inválida',
        responsibleUserId: 'demo-almacen',
      ),
      throwsStateError,
    );

    final unchanged = (await repository.list()).firstWhere(
      (value) => value.variantId == item.variantId,
    );
    expect(unchanged.physicalStock, item.physicalStock);
    expect(await repository.movements(variantId: item.variantId), isEmpty);
  });

  test('adjustment can set physical stock to zero', () async {
    final item = (await repository.list()).first;

    await repository.registerMovement(
      variantId: item.variantId,
      type: StockMovementType.adjustment,
      quantity: 0,
      reason: 'Conteo físico sin unidades',
      responsibleUserId: 'demo-almacen',
    );

    final updated = (await repository.list()).firstWhere(
      (value) => value.variantId == item.variantId,
    );
    expect(updated.physicalStock, 0);
    expect(
      (await repository.movements(variantId: item.variantId)).single.quantity,
      0,
    );
  });
}
