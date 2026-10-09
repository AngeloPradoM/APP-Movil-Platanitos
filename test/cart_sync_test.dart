import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/features/auth/data/auth_repository.dart';
import 'package:platanitos_app/features/cart/data/cart_repository.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

const _variants = {
  'variant-40': {'sizeValue': '40', 'stock': 3},
  'variant-39': {'sizeValue': '39', 'stock': 5},
};

class _FakeBackend extends http.BaseClient {
  final requests = <String>[];
  final syncBodies = <List<dynamic>>[];
  final remoteQuantities = <String, int>{};
  int? failStatus;
  String failMessage = 'Error interno';
  int _itemSequence = 0;
  final _itemIds = <String, String>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final key = '${request.method} $path';
    requests.add(key);
    final body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body) as Map<String, dynamic>
        : const <String, dynamic>{};
    if (path.startsWith('/auth/')) return _json(_session());
    if (path == '/catalog/products') return _json(_catalog());
    if (path.startsWith('/cart') &&
        request.method != 'GET' &&
        failStatus != null) {
      return _json({'message': failMessage}, failStatus!);
    }
    switch (key) {
      case 'GET /cart':
        break;
      case 'POST /cart/sync':
        final items = body['items'] as List<dynamic>;
        syncBodies.add(items);
        for (final item in items.cast<Map<String, dynamic>>()) {
          _add(item['variantId'] as String, item['quantity'] as int);
        }
      case 'POST /cart/items':
        _add(body['variantId'] as String, body['quantity'] as int);
      default:
        final itemId = path.split('/').last;
        final variantId = _itemIds.entries
            .firstWhere((entry) => entry.value == itemId)
            .key;
        final quantity = request.method == 'PATCH'
            ? body['quantity'] as int
            : 0;
        if (quantity == 0) {
          remoteQuantities.remove(variantId);
        } else {
          remoteQuantities[variantId] = quantity;
        }
    }
    return _json(_cart());
  }

  void _add(String variantId, int quantity) {
    remoteQuantities[variantId] = (remoteQuantities[variantId] ?? 0) + quantity;
  }

  Map<String, dynamic> _session() => {
    'accessToken': 'access-token',
    'refreshToken': 'refresh-token',
    'user': {'name': 'Cliente Remoto', 'email': 'cliente@test.pe'},
  };

  Map<String, dynamic> _variantJson(String id) => {
    'id': id,
    'sku': 'SKU-$id',
    'sizeSystem': 'EUR',
    'sizeValue': _variants[id]!['sizeValue'],
    'color': 'Negro',
    'price': '199.90',
    'stock': _variants[id]!['stock'],
  };

  Map<String, dynamic> _catalog() => {
    'data': [
      {
        'id': 'product-uuid',
        'name': 'Producto remoto',
        'slug': 'producto-remoto',
        'description': null,
        'brand': {'name': 'Marca', 'slug': 'marca'},
        'category': {'name': 'Zapatillas', 'slug': 'zapatillas'},
        'images': <Map<String, dynamic>>[],
        'variants': [for (final id in _variants.keys) _variantJson(id)],
      },
    ],
    'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
  };

  Map<String, dynamic> _cart() => {
    'id': 'cart-uuid',
    'status': 'ACTIVE',
    'items': [
      for (final entry in remoteQuantities.entries)
        {
          'id': _itemIds.putIfAbsent(
            entry.key,
            () => 'item-${++_itemSequence}',
          ),
          'quantity': entry.value,
          'variant': {
            ..._variantJson(entry.key),
            'product': {'name': 'Producto remoto', 'slug': 'producto-remoto'},
          },
          'subtotal': '0.00',
        },
    ],
    'subtotal': '0.00',
    'itemCount': remoteQuantities.values.fold(0, (sum, value) => sum + value),
  };

  http.StreamedResponse _json(Object payload, [int status = 200]) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(payload))),
        status,
        headers: {'content-type': 'application/json'},
      );
}

ShopState _buildState(_FakeBackend backend) {
  final client = ApiClient(baseUrl: 'http://test', client: backend);
  return ShopState(
    seedHistory: false,
    catalogRepository: CatalogRepository(client: client),
    authRepository: AuthRepository(client: client),
    cartRepository: CartRepository(client: client),
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

int _size40(Product product) => product.sizes.indexOf('40');

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('el login sin carrito local carga la bolsa desde GET /cart', () async {
    final backend = _FakeBackend()..remoteQuantities['variant-40'] = 2;
    final state = _buildState(backend);
    addTearDown(state.dispose);

    await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');

    expect(backend.requests, contains('GET /cart'));
    expect(backend.requests, isNot(contains('POST /cart/sync')));
    expect(state.cart.single.quantity, 2);
    expect(state.cart.single.size, '40');
    expect(state.cart.single.remoteItemId, isNotNull);
    expect(state.cart.single.product.remoteId, 'product-uuid');
    expect(state.cartError, isNull);

    state.placeOrder(PaymentMethod.cash);
    await _settle();
    expect(backend.requests, contains('DELETE /cart/items/item-1'));
    expect(backend.remoteQuantities, isEmpty);
  });

  test(
    'el login con carrito local suma cantidades sin superar el stock',
    () async {
      final backend = _FakeBackend()..remoteQuantities['variant-40'] = 1;
      final state = _buildState(backend);
      addTearDown(state.dispose);
      await state.loadRemoteCatalog();
      final remoteProduct = state.catalogProducts.single;
      for (var i = 0; i < 3; i++) {
        state.addToCart(remoteProduct, _size40(remoteProduct), SizeSystem.eur);
      }
      state.addToCart(products[0], 2, SizeSystem.eur);
      expect(backend.requests, isNot(contains('POST /cart/items')));

      await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');

      expect(backend.syncBodies.single, [
        {'variantId': 'variant-40', 'quantity': 2},
      ]);
      final remoteItem = state.cart.firstWhere(
        (item) => item.remoteVariantId != null,
      );
      expect(remoteItem.quantity, 3);
      expect(remoteItem.remoteItemId, isNotNull);
      expect(
        state.cart.where((item) => item.product.id == products[0].id),
        hasLength(1),
      );
    },
  );

  test(
    'los cambios con sesión llegan al backend y se revierten si fallan',
    () async {
      final backend = _FakeBackend();
      final state = _buildState(backend);
      addTearDown(state.dispose);
      await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');
      final remoteProduct = state.catalogProducts.single;

      state.addToCart(remoteProduct, _size40(remoteProduct), SizeSystem.eur);
      await _settle();
      expect(backend.requests, contains('POST /cart/items'));
      expect(state.cart.single.remoteItemId, isNotNull);

      backend.failStatus = 500;
      state.changeQuantity(state.cart.single, 1);
      expect(state.cart.single.quantity, 2);
      await _settle();
      expect(backend.requests, contains('PATCH /cart/items/item-1'));
      expect(state.cart.single.quantity, 1);
      expect(
        state.cartError,
        'El sistema está fallando en este momento. Intenta más tarde.',
      );

      backend
        ..failStatus = 400
        ..failMessage = 'La cantidad supera el stock disponible';
      state.addToCart(remoteProduct, _size40(remoteProduct), SizeSystem.eur);
      expect(state.cart.single.quantity, 2);
      await _settle();
      expect(state.cart.single.quantity, 1);
      expect(state.cartError, 'No hay más stock disponible para esta talla.');

      backend.failStatus = null;
      state.removeItem(state.cart.single);
      await _settle();
      expect(state.cart, isEmpty);
      expect(backend.remoteQuantities, isEmpty);
      expect(state.cartError, isNull);
    },
  );

  test('restaurar la sesión carga el carrito remoto', () async {
    FlutterSecureStorage.setMockInitialValues({
      'platanitos.access_token': 'old-access',
      'platanitos.refresh_token': 'old-refresh',
    });
    final backend = _FakeBackend()..remoteQuantities['variant-39'] = 1;
    final state = _buildState(backend);
    addTearDown(state.dispose);

    await state.restoreSession();

    expect(state.signedIn, isTrue);
    expect(backend.requests, contains('POST /auth/refresh'));
    expect(state.cart.single.size, '39');
    expect(state.cart.single.quantity, 1);
  });
}
