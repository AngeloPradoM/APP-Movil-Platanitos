part of '../../../../app/state/shop_state.dart';

extension AccountController on ShopState {
  Future<void> _loadAccountData() async {
    final token = accessToken;
    if (token == null) return;
    final favoritesSource = favoritesRepository;
    final ordersSource = ordersRepository;
    final addressesSource = addressesRepository;
    await Future.wait([
      if (addressesSource != null)
        _keepLocalOnFailure(
          () async => _applyRemoteAddresses(
            await addressesSource.list(accessToken: token),
          ),
        ),
      if (favoritesSource != null)
        _keepLocalOnFailure(
          () async => _applyRemoteFavorites(
            await favoritesSource.list(accessToken: token),
          ),
        ),
      if (ordersSource != null)
        _keepLocalOnFailure(
          () async =>
              _applyRemoteOrders(await ordersSource.list(accessToken: token)),
        ),
      _refreshLoyalty(token),
    ]);
    _notifySafely();
  }

  Future<void> _keepLocalOnFailure(Future<void> Function() request) async {
    try {
      await request();
    } catch (_) {}
  }

  void updateUser(AppUser value) {
    user = value;
    _notifySafely();
  }

  /// Guarda nombre, correo y teléfono en el backend cuando hay sesión.
  Future<void> saveProfile(AppUser value) async {
    final repository = authRepository;
    final token = _sessionToken;
    if (repository == null || token == null) return updateUser(value);
    final Map<String, dynamic> remote;
    try {
      remote = await repository.updateProfile(
        accessToken: token,
        name: value.name,
        email: value.email,
        phone: value.phone,
      );
    } catch (error) {
      throw StateError(_requestErrorMessage(error));
    }
    updateUser(
      AppUser(
        name: remote['name'] as String? ?? value.name,
        document: value.document,
        email: remote['email'] as String? ?? value.email,
        phone: remote['phone'] as String? ?? value.phone,
        role: UserRole.fromJson(remote['role']),
      ),
    );
  }
}
