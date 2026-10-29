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
    _syncToken();
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
      id: remoteUser['id'] as String?,
      name: remoteUser['name'] as String? ?? user.name,
      document: remoteUser['documentNumber'] as String? ?? user.document,
      email: remoteUser['email'] as String? ?? email,
      phone: remoteUser['phone'] as String? ?? user.phone,
      role: UserRole.fromJson(remoteUser['role']),
    );
    signedIn = true;
    _syncToken();
    _startLive();
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
      id: session.user['id'] as String?,
      name: session.user['name'] as String? ?? name,
      document:
          '${session.user['documentType'] ?? documentType ?? ''} ${session.user['documentNumber'] ?? documentNumber ?? ''}'
              .trim(),
      email: session.user['email'] as String? ?? email,
      phone: session.user['phone'] as String? ?? phone ?? user.phone,
      role: UserRole.fromJson(session.user['role']),
    );
    signedIn = true;
    _syncToken();
    _startLive();
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
        id: remoteUser['id'] as String?,
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
      _syncToken();
      _startLive();
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
    _stopLive();
    _syncToken();
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

  void _syncToken() {
    tokenStore?.value = _authSession?.accessToken;
  }

  void _startLive() {
    _stopLive();
    final token = accessToken;
    if (token == null || ordersRepository == null) return;
    _liveSub = LiveStream(ApiConfig.baseUrl).listen(token).listen(_onLive);
    _livePoll = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollLive());
    });
  }

  void _stopLive() {
    _liveSub?.cancel();
    _liveSub = null;
    _livePoll?.cancel();
    _livePoll = null;
    _liveCursor = '';
  }

  Future<void> _pollLive() async {
    final token = accessToken;
    if (token == null || _disposed) return;
    try {
      final payload = await ApiClient(baseUrl: ApiConfig.baseUrl).get(
        '/live/head',
        accessToken: token,
      );
      final cursor = (payload as Map)['cursor'] as String? ?? '';
      if (cursor.isEmpty || cursor == _liveCursor) return;
      _onLive({'type': 'poll', 'at': cursor});
    } catch (_) {}
  }

  void _onLive(Map<String, dynamic> event) {
    if (_disposed) return;
    final type = event['type'] as String? ?? '';
    if (type == 'ping') return;
    final at = event['at'] as String?;
    if (at != null && at.isNotEmpty) {
      if (at == _liveCursor && type == 'poll') return;
      _liveCursor = at;
    }
    liveRevision++;
    final token = accessToken;
    final source = ordersRepository;
    if (token != null && source != null && (type.startsWith('order') || type == 'poll')) {
      unawaited(
        source.list(accessToken: token).then((orders) {
          if (_disposed) return;
          _applyRemoteOrders(orders);
          _notifySafely();
        }, onError: (_, _) {}),
      );
    }
    if (type == 'catalog.updated') unawaited(loadCategories());
    _notifySafely();
  }
}
