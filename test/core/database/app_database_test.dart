import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/core/database/app_database.dart';
import 'package:platanitos_app/features/auth/data/local_auth_repository.dart';
import 'package:platanitos_app/features/auth/domain/user_models.dart';
import 'package:platanitos_app/features/catalog/data/local_catalog_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase appDatabase;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    appDatabase = await AppDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => appDatabase.close());

  test('migration creates demo profiles and catalog variants', () async {
    final auth = LocalAuthRepository(appDatabase);
    final catalog = LocalCatalogRepository(appDatabase);

    final profiles = await auth.profiles();
    final page = await catalog.listProducts(limit: 50);

    expect(profiles, hasLength(6));
    expect(
      profiles.map((user) => user.role),
      containsAll(<UserRole>[
        UserRole.cliente,
        UserRole.almacen,
        UserRole.repartidor,
        UserRole.atencionCliente,
        UserRole.administrador,
        UserRole.trabajadorTienda,
      ]),
    );
    expect(page.products, hasLength(4));
    expect(
      page.products.every((product) => product.variants.length == 6),
      isTrue,
    );
    final tables = await appDatabase.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tables.map((row) => row['name']),
      containsAll(<String>[
        'cart_items',
        'orders',
        'order_items',
        'simulated_payments',
        'order_preparations',
        'deliveries',
        'delivery_events',
        'delivery_evidence',
        'incidents',
        'support_requests',
        'store_reservations',
      ]),
    );
  });

  test('demo session is stored and removed locally', () async {
    final auth = LocalAuthRepository(appDatabase);
    expect(await auth.restoreSession(), isNull);

    final selected = await auth.signIn('demo-almacen');
    expect(selected.role, UserRole.almacen);
    expect((await auth.restoreSession())?.id, 'demo-almacen');

    await auth.signOut();
    expect(await auth.restoreSession(), isNull);
  });

  test('migration from version 2 allows adjustment to zero', () async {
    final directory = await Directory.systemTemp.createTemp('platanitos-db-');
    final databasePath = '${directory.path}${Platform.pathSeparator}upgrade.db';
    addTearDown(() async {
      await databaseFactoryFfi.deleteDatabase(databasePath);
      await directory.delete(recursive: true);
    });
    final legacy = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE demo_users (
              id TEXT PRIMARY KEY, name TEXT NOT NULL, document TEXT NOT NULL,
              email TEXT NOT NULL, phone TEXT NOT NULL, role TEXT NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE product_variants (
              id TEXT PRIMARY KEY, product_id TEXT NOT NULL,
              size_system TEXT NOT NULL, size_value TEXT NOT NULL,
              color TEXT NOT NULL, physical_stock INTEGER NOT NULL,
              reserved_stock INTEGER NOT NULL
            )
          ''');
          await database.execute('''
            CREATE TABLE stock_movements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              variant_id TEXT NOT NULL REFERENCES product_variants(id),
              type TEXT NOT NULL,
              quantity INTEGER NOT NULL CHECK (quantity > 0),
              reason TEXT NOT NULL,
              responsible_user_id TEXT NOT NULL REFERENCES demo_users(id),
              created_at TEXT NOT NULL
            )
          ''');
          await database.execute(
            'CREATE INDEX idx_stock_movements_variant_date '
            'ON stock_movements(variant_id, created_at DESC)',
          );
        },
      ),
    );
    await legacy.close();

    final upgraded = await AppDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    addTearDown(upgraded.close);
    final schema = await upgraded.database.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'stock_movements'",
    );
    expect(schema.single['sql'], contains('quantity >= 0'));
  });

  test('migration from version 4 creates delivery evidence storage', () async {
    final directory = await Directory.systemTemp.createTemp('platanitos-db-');
    final databasePath = '${directory.path}${Platform.pathSeparator}upgrade.db';
    addTearDown(() async {
      await databaseFactoryFfi.deleteDatabase(databasePath);
      await directory.delete(recursive: true);
    });
    final legacy = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (database, _) async {
          await database.execute('''
            CREATE TABLE deliveries (
              id TEXT PRIMARY KEY
            )
          ''');
        },
      ),
    );
    await legacy.close();

    final upgraded = await AppDatabase.open(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    addTearDown(upgraded.close);
    final tables = await upgraded.database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'delivery_evidence'",
    );
    expect(tables, hasLength(1));
  });
}
