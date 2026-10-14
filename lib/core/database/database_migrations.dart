import 'package:sqflite/sqflite.dart';

abstract final class DatabaseMigrations {
  static const currentVersion = 5;

  static Future<void> create(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE demo_users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        document TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE demo_session (
        singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
        user_id TEXT NOT NULL REFERENCES demo_users(id)
      )
    ''');
    batch.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        local_id INTEGER NOT NULL UNIQUE,
        slug TEXT NOT NULL UNIQUE,
        brand TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
        compare_price_cents INTEGER,
        image TEXT NOT NULL,
        color TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    batch.execute('''
      CREATE TABLE product_variants (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL REFERENCES products(id),
        size_system TEXT NOT NULL,
        size_value TEXT NOT NULL,
        color TEXT NOT NULL,
        physical_stock INTEGER NOT NULL CHECK (physical_stock >= 0),
        reserved_stock INTEGER NOT NULL DEFAULT 0 CHECK (reserved_stock >= 0),
        UNIQUE(product_id, size_system, size_value, color),
        CHECK (reserved_stock <= physical_stock)
      )
    ''');
    batch.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        variant_id TEXT NOT NULL REFERENCES product_variants(id),
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity >= 0),
        reason TEXT NOT NULL,
        responsible_user_id TEXT NOT NULL REFERENCES demo_users(id),
        created_at TEXT NOT NULL
      )
    ''');
    for (final statement in _workflowSchema) {
      batch.execute(statement);
    }
    batch.execute('CREATE INDEX idx_products_category ON products(category)');
    batch.execute(
      'CREATE INDEX idx_variants_product ON product_variants(product_id)',
    );
    batch.execute(
      'CREATE INDEX idx_stock_movements_variant_date ON stock_movements(variant_id, created_at DESC)',
    );

    for (final user in _users) {
      batch.insert('demo_users', user);
    }
    for (final product in _products) {
      final productRow = Map<String, Object>.from(product)
        ..remove('color_slug');
      batch.insert('products', productRow);
      for (var size = 35; size <= 40; size++) {
        batch.insert('product_variants', {
          'id': '${product['id']}-$size-${product['color_slug']}',
          'product_id': product['id'],
          'size_system': 'EUR',
          'size_value': '$size',
          'color': product['color'],
          'physical_stock': size == 35 ? 2 : 8 + (size % 3),
          'reserved_stock': 0,
        });
      }
    }
    await batch.commit(noResult: true);
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      for (final statement in _workflowSchema) {
        await db.execute(
          statement.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'),
        );
      }
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE stock_movements RENAME TO stock_movements_v2',
      );
      await db.execute('''
        CREATE TABLE stock_movements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          variant_id TEXT NOT NULL REFERENCES product_variants(id),
          type TEXT NOT NULL,
          quantity INTEGER NOT NULL CHECK (quantity >= 0),
          reason TEXT NOT NULL,
          responsible_user_id TEXT NOT NULL REFERENCES demo_users(id),
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO stock_movements
          (id, variant_id, type, quantity, reason, responsible_user_id, created_at)
        SELECT id, variant_id, type, quantity, reason, responsible_user_id, created_at
        FROM stock_movements_v2
      ''');
      await db.execute('DROP TABLE stock_movements_v2');
      await db.execute(
        'CREATE INDEX idx_stock_movements_variant_date ON stock_movements(variant_id, created_at DESC)',
      );
    }
    if (oldVersion < 4) {
      for (final statement in _workflowSchema) {
        await db.execute(
          statement.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'),
        );
      }
      final orderColumns = (await db.rawQuery('PRAGMA table_info(orders)'))
          .map((column) => column['name'])
          .toSet();
      if (!orderColumns.contains('payment_method')) {
        await db.execute(
          "ALTER TABLE orders ADD COLUMN payment_method TEXT NOT NULL DEFAULT 'WALLET'",
        );
      }
      if (!orderColumns.contains('address')) {
        await db.execute(
          "ALTER TABLE orders ADD COLUMN address TEXT NOT NULL DEFAULT ''",
        );
      }
      await db.insert(
        'demo_users',
        _storeWorker,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        _deliveryEvidenceSchema.replaceFirst(
          'CREATE TABLE',
          'CREATE TABLE IF NOT EXISTS',
        ),
      );
    }
  }

  static const _workflowSchema = <String>[
    '''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL REFERENCES demo_users(id),
        variant_id TEXT NOT NULL REFERENCES product_variants(id),
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        UNIQUE(user_id, variant_id)
      )
    ''',
    '''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        public_number TEXT NOT NULL UNIQUE,
        user_id TEXT NOT NULL REFERENCES demo_users(id),
        status TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        shipping_cents INTEGER NOT NULL DEFAULT 0 CHECK (shipping_cents >= 0),
        address TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL REFERENCES orders(id),
        variant_id TEXT REFERENCES product_variants(id),
        product_name TEXT NOT NULL,
        size_system TEXT NOT NULL,
        size_value TEXT NOT NULL,
        color TEXT NOT NULL,
        unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
        quantity INTEGER NOT NULL CHECK (quantity > 0)
      )
    ''',
    '''
      CREATE TABLE simulated_payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL REFERENCES orders(id),
        method TEXT NOT NULL,
        status TEXT NOT NULL,
        amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
        message TEXT,
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE order_preparations (
        order_id TEXT PRIMARY KEY REFERENCES orders(id),
        status TEXT NOT NULL,
        assigned_user_id TEXT REFERENCES demo_users(id),
        started_at TEXT,
        completed_at TEXT
      )
    ''',
    '''
      CREATE TABLE deliveries (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL UNIQUE REFERENCES orders(id),
        assigned_user_id TEXT REFERENCES demo_users(id),
        status TEXT NOT NULL,
        assigned_at TEXT,
        delivered_at TEXT
      )
    ''',
    '''
      CREATE TABLE delivery_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        delivery_id TEXT NOT NULL REFERENCES deliveries(id),
        status TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''',
    _deliveryEvidenceSchema,
    '''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        delivery_id TEXT NOT NULL REFERENCES deliveries(id),
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''',
    '''
      CREATE TABLE support_requests (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL REFERENCES orders(id),
        user_id TEXT NOT NULL REFERENCES demo_users(id),
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''',
    _storeReservationsSchema,
  ];

  static const _deliveryEvidenceSchema = '''
    CREATE TABLE delivery_evidence (
      delivery_id TEXT PRIMARY KEY REFERENCES deliveries(id),
      recipient_name TEXT NOT NULL,
      signature_data TEXT NOT NULL,
      photo_bytes BLOB NOT NULL,
      captured_at TEXT NOT NULL
    )
  ''';

  static const _storeReservationsSchema = '''
    CREATE TABLE store_reservations (
      id TEXT PRIMARY KEY,
      variant_id TEXT NOT NULL REFERENCES product_variants(id),
      customer_name TEXT NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      status TEXT NOT NULL,
      worker_id TEXT NOT NULL REFERENCES demo_users(id),
      created_at TEXT NOT NULL,
      expires_at TEXT NOT NULL
    )
  ''';

  static const _storeWorker = <String, Object>{
    'id': 'demo-tienda',
    'name': 'Carlos Tienda',
    'document': 'DEMO TDA-01',
    'email': 'tienda@demo.local',
    'phone': '+51900000005',
    'role': 'TRABAJADOR_TIENDA',
  };

  static const _users = <Map<String, Object>>[
    {
      'id': 'demo-cliente',
      'name': 'Daniela Rojas',
      'document': 'DNI 74281639',
      'email': 'cliente@demo.local',
      'phone': '+51987654321',
      'role': 'CLIENTE',
    },
    {
      'id': 'demo-almacen',
      'name': 'Marco Almacén',
      'document': 'DEMO ALM-01',
      'email': 'almacen@demo.local',
      'phone': '+51900000001',
      'role': 'ALMACEN',
    },
    {
      'id': 'demo-repartidor',
      'name': 'Luis Repartidor',
      'document': 'DEMO REP-01',
      'email': 'repartidor@demo.local',
      'phone': '+51900000002',
      'role': 'REPARTIDOR',
    },
    {
      'id': 'demo-atencion',
      'name': 'Ana Atención',
      'document': 'DEMO ATC-01',
      'email': 'atencion@demo.local',
      'phone': '+51900000003',
      'role': 'ATENCION_CLIENTE',
    },
    {
      'id': 'demo-administrador',
      'name': 'Rosa Administradora',
      'document': 'DEMO ADM-01',
      'email': 'admin@demo.local',
      'phone': '+51900000004',
      'role': 'ADMINISTRADOR',
    },
    _storeWorker,
  ];

  static const _products = <Map<String, Object>>[
    {
      'id': 'product-1',
      'local_id': 1,
      'slug': 'zapatilla-plataforma',
      'brand': 'PLATANITOS',
      'name': 'Zapatilla Plataforma',
      'description': 'Producto de demostración',
      'category': 'Zapatillas',
      'price_cents': 8990,
      'compare_price_cents': 12990,
      'image': 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?fit=crop&q=85&w=800',
      'color': 'Blanco',
      'active': 1,
      'color_slug': 'blanco',
    },
    {
      'id': 'product-2',
      'local_id': 2,
      'slug': 'botines-chelsea-abril',
      'brand': 'VIZZANO',
      'name': 'Botines Chelsea Abril',
      'description': 'Producto de demostración',
      'category': 'Botines',
      'price_cents': 15990,
      'compare_price_cents': 21990,
      'image': 'https://images.unsplash.com/photo-1605732440685-d0654d81aa30?fit=crop&q=85&w=800',
      'color': 'Negro',
      'active': 1,
      'color_slug': 'negro',
    },
    {
      'id': 'product-3',
      'local_id': 3,
      'slug': 'tacos-amelia',
      'brand': 'BEIRA RIO',
      'name': 'Tacos Amelia',
      'description': 'Producto de demostración',
      'category': 'Tacos',
      'price_cents': 11990,
      'compare_price_cents': 16990,
      'image': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?fit=crop&q=85&w=800',
      'color': 'Floral',
      'active': 1,
      'color_slug': 'floral',
    },
    {
      'id': 'product-4',
      'local_id': 4,
      'slug': 'sandalias-taco-cuadrado',
      'brand': 'PLATANITOS',
      'name': 'Sandalias Taco Cuadrado',
      'description': 'Producto de demostración',
      'category': 'Sandalias',
      'price_cents': 7990,
      'compare_price_cents': 11990,
      'image': 'https://images.unsplash.com/photo-1591884807537-0bce39888fe0?fit=crop&q=85&w=800',
      'color': 'Camel',
      'active': 1,
      'color_slug': 'camel',
    },
  ];
}
