part of '../../../../app/state/shop_state.dart';

extension FavoritesController on ShopState {
  void _applyRemoteFavorites(List<CatalogProduct> remote) {
    final mapped = remote.map((product) => product.toShopProduct()).toList();
    _favoriteProducts
      ..clear()
      ..addEntries(mapped.map((product) => MapEntry(product.id, product)));
    // El backend devuelve primero el más reciente; localmente va al final.
    _favorites
      ..clear()
      ..addAll(mapped.reversed.map((product) => product.id));
  }

  void toggleFavorite(int id) {
    final adding = !_favorites.contains(id);
    adding ? _favorites.add(id) : _favorites.remove(id);
    _notifySafely();
    final repository = favoritesRepository;
    final token = _sessionToken;
    final productId = _productById(id)?.remoteId;
    if (repository == null || token == null || productId == null) return;
    unawaited(() async {
      try {
        _applyRemoteFavorites(
          adding
              ? await repository.add(accessToken: token, productId: productId)
              : await repository.remove(
                  accessToken: token,
                  productId: productId,
                ),
        );
      } catch (_) {
        adding ? _favorites.remove(id) : _favorites.add(id);
      }
      _notifySafely();
    }());
  }
}
