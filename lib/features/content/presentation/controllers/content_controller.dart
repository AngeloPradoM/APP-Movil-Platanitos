part of '../../../../app/state/shop_state.dart';

extension ContentController on ShopState {
  Future<void> loadContent() async {
    final repository = contentRepository;
    if (repository == null) return;
    await _keepLocalOnFailure(() async {
      final (remoteStores, remoteArticles) = await (
        repository.listStores(),
        repository.listArticles(),
      ).wait;
      if (remoteStores.isNotEmpty) _stores = remoteStores;
      if (remoteArticles.isNotEmpty) _articles = remoteArticles;
      _notifySafely();
    });
  }
}
