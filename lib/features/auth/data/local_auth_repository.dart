import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/repositories/auth_repository_contract.dart';
import '../domain/user_models.dart';

class LocalAuthRepository implements DemoAuthRepository {
  LocalAuthRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<AppUser>> profiles() async {
    final rows = await _appDatabase.database.query(
      'demo_users',
      orderBy: 'rowid',
    );
    return rows.map(_userFromRow).toList(growable: false);
  }

  @override
  Future<AppUser?> restoreSession() async {
    final rows = await _appDatabase.database.rawQuery('''
      SELECT u.* FROM demo_session s
      JOIN demo_users u ON u.id = s.user_id
      WHERE s.singleton = 1
      LIMIT 1
    ''');
    return rows.isEmpty ? null : _userFromRow(rows.first);
  }

  @override
  Future<AppUser> signIn(String profileId) async {
    final rows = await _appDatabase.database.query(
      'demo_users',
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('El perfil de demostración no existe.');
    await _appDatabase.database.insert('demo_session', {
      'singleton': 1,
      'user_id': profileId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return _userFromRow(rows.first);
  }

  @override
  Future<void> signOut() => _appDatabase.database.delete('demo_session');

  AppUser _userFromRow(Map<String, Object?> row) => AppUser(
    id: row['id'] as String,
    name: row['name'] as String,
    document: row['document'] as String,
    email: row['email'] as String,
    phone: row['phone'] as String,
    role: UserRole.fromJson(row['role']),
  );
}
