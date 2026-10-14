part of '../../../../app/state/shop_state.dart';

extension AddressesController on ShopState {
  void _applyRemoteAddresses(List<ShippingAddress> remote) {
    _addresses
      ..clear()
      ..addAll(remote);
  }

  /// Crea o actualiza una dirección. Con sesión se guarda en el backend;
  /// sin ella queda en el dispositivo.
  Future<void> saveAddress(ShippingAddress address) async {
    final repository = addressesRepository;
    final token = _sessionToken;
    if (repository != null && token != null) {
      try {
        _applyRemoteAddresses(
          address.isRemote
              ? await repository.update(accessToken: token, address: address)
              : await repository.create(accessToken: token, address: address),
        );
      } catch (error) {
        throw StateError(_requestErrorMessage(error));
      }
      _notifySafely();
      return;
    }
    final index = _addresses.indexWhere((item) => item.id == address.id);
    final makeDefault =
        address.isDefault ||
        _addresses.isEmpty ||
        (index >= 0 && _addresses[index].isDefault);
    final saved = address.copyWith(
      id: index >= 0 ? address.id : 'local-${++_addressSequence}',
      isDefault: makeDefault,
    );
    if (index >= 0) _addresses.removeAt(index);
    if (makeDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
      _addresses.insert(0, saved);
    } else {
      _addresses.insert(index >= 0 ? index : _addresses.length, saved);
    }
    _notifySafely();
  }

  Future<void> removeAddress(ShippingAddress address) async {
    final repository = addressesRepository;
    final token = _sessionToken;
    if (repository != null && token != null && address.isRemote) {
      try {
        _applyRemoteAddresses(
          await repository.remove(accessToken: token, id: address.id!),
        );
      } catch (error) {
        throw StateError(_requestErrorMessage(error));
      }
      _notifySafely();
      return;
    }
    _addresses.removeWhere((item) => item.id == address.id);
    if (address.isDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    _notifySafely();
  }
}
