part of '../../../../app/state/shop_state.dart';

extension AuthController on ShopState {
  Future<List<AppUser>> demoProfiles() async =>
      await demoAuthRepository?.profiles() ?? const [];

  Future<void> loginDemo(String profileId) async {
    final repository = demoAuthRepository;
    if (repository == null) {
      throw StateError('El modo demostrativo no está configurado.');
    }
    user = await repository.signIn(profileId);
    signedIn = true;
    if (_addresses.isEmpty) _addresses.add(demoAddress);
    await loadDemoCommerce(mergeCart: true);
    _notifySafely();
  }

  void login({AppUser? account}) {
    user = account ?? user;
    signedIn = true;
    if (_addresses.isEmpty && _authSession == null) _addresses.add(demoAddress);
    _notifySafely();
  }

  Future<void> loginRemote({
    required String email,
    required String password,
  }) async {
    final repository = authRepository;
    if (repository == null) {
      throw StateError('Autenticación remota no configurada');
    }
    final session = await repository.login(email: email, password: password);
    _authSession = session;
    await _sessionStorage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await loadRemoteCart();
    await _loadAccountData();
    final remoteUser = session.user;
    user = AppUser(
      name: remoteUser['name'] as String? ?? user.name,
      document: remoteUser['documentNumber'] as String? ?? user.document,
      email: remoteUser['email'] as String? ?? email,
      phone: remoteUser['phone'] as String? ?? user.phone,
      role: UserRole.fromJson(remoteUser['role']),
    );
    signedIn = true;
    _notifySafely();
  }

  Future<void> registerRemote({
    required String email,
    required String name,
    required String password,
    String? phone,
    String? documentType,
    String? documentNumber,
  }) async {
    final repository = authRepository;
    if (repository == null) {
      throw StateError('Autenticación remota no configurada');
    }
    final session = await repository.register(
      email: email,
      name: name,
      password: password,
      phone: phone,
      documentType: documentType,
      documentNumber: documentNumber,
    );
    _authSession = session;
    await _sessionStorage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    await loadRemoteCart();
    await _loadAccountData();
    user = AppUser(
      name: session.user['name'] as String? ?? name,
      document:
          '${session.user['documentType'] ?? documentType ?? ''} ${session.user['documentNumber'] ?? documentNumber ?? ''}'
              .trim(),
      email: session.user['email'] as String? ?? email,
      phone: session.user['phone'] as String? ?? phone ?? user.phone,
      role: UserRole.fromJson(session.user['role']),
    );
    signedIn = true;
    _notifySafely();
  }

  Future<void> restoreSession() async {
    final localRepository = demoAuthRepository;
    if (localRepository != null) {
      final restoredUser = await localRepository.restoreSession();
      if (restoredUser != null) {
        user = restoredUser;
        signedIn = true;
        if (_addresses.isEmpty) _addresses.add(demoAddress);
        await loadDemoCommerce();
        _notifySafely();
      }
      return;
    }
    if (authRepository == null) return;
    final stored = await _sessionStorage.read();
    if (stored == null) return;
    try {
      final session = await authRepository!.refresh(stored.refreshToken);
      _authSession = session;
      final remoteUser = session.user;
      user = AppUser(
        name: remoteUser['name'] as String? ?? user.name,
        document: remoteUser['documentNumber'] as String? ?? user.document,
        email: remoteUser['email'] as String? ?? user.email,
        phone: remoteUser['phone'] as String? ?? user.phone,
        role: UserRole.fromJson(remoteUser['role']),
      );
      signedIn = true;
      await _sessionStorage.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await loadRemoteCart();
      await _loadAccountData();
      _notifySafely();
    } catch (_) {
      await _sessionStorage.clear();
    }
  }

  /// Fusiona el carrito local con el guardado en el servidor sumando
  /// cantidades por variante, sin superar el stock disponible.
  void logout() {
    final localRepository = demoAuthRepository;
    if (localRepository != null) unawaited(localRepository.signOut());
    final refreshToken = _authSession?.refreshToken;
    if (refreshToken != null && authRepository != null) {
      authRepository!.logout(refreshToken).catchError((_) {});
    }
    _authSession = null;
    _sessionStorage.clear();
    signedIn = false;
    _cart.clear();
    _cartError = null;
    _orders.removeWhere((order) => order.remote);
    _favorites
      ..clear()
      ..addAll(ShopState._demoFavorites);
    _favoriteProducts.clear();
    _cartProducts.clear();
    _addresses.clear();
    _loyalty = null;
    catalog.clear();
    _notifySafely();
  }
}
