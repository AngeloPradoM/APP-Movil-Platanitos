import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_migrations.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? databasePath,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final resolvedPath =
        databasePath ??
        path.join(
          await selectedFactory.getDatabasesPath(),
          'platanitos_demo.db',
        );
    final db = await selectedFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: DatabaseMigrations.currentVersion,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: DatabaseMigrations.create,
        onUpgrade: DatabaseMigrations.upgrade,
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => database.close();
}
