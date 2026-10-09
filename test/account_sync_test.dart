import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/features/account/data/account_repository.dart';
import 'package:platanitos_app/features/account/data/content_repository.dart';
import 'package:platanitos_app/features/auth/data/auth_repository.dart';
import 'package:platanitos_app/features/cart/data/cart_repository.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/features/catalog/data/favorites_repository.dart';
import 'package:platanitos_app/features/orders/data/orders_repository.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

const _productId = 'product-uuid';
const _variantId = 'variant-40';

class _FakeBackend extends http.BaseClient {
  final requests = <String>[];
  final bodies = <String, Map<String, dynamic>>{};
  final failures = <String, (int, String)>{};
  bool favorite = false;
  int cartQuantity = 0;
  final orders = <Map<String, dynamic>>[];
  int points = 0, lifetimePoints = 0;
  double wallet = 0;
  final movements = <Map<String, dynamic>>[];
  Map<String, dynamic> user = {
    'name': 'Cliente Remoto',
    'email': 'cliente@test.pe',
    'phone': '912345678',
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    final key = '${request.method} $path';
    requests.add(key);
    final body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body) as Map<String, dynamic>
        : const <String, dynamic>{};
    bodies[key] = body;
    final failure = failures[key];
    if (failure != null) return _json({'message': failure.$2}, failure.$1);
    if (path.startsWith('/auth/')) {
      return _json({
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'user': user,
      });
    }
    switch (key) {
      case 'GET /catalog/products':
        return _json({
          'data': [_product()],
          'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
        });
      case 'POST /cart/items':
        cartQuantity += body['quantity'] as int;
        return _json(_cart());
      case 'GET /cart':
        return _json(_cart());
      case 'GET /favorites':
        return _json(_favorites());
      case 'PUT /favorites/$_productId':
        favorite = true;
        return _json(_favorites());
      case 'DELETE /favorites/$_productId':
        favorite = false;
        return _json(_favorites());
      case 'GET /orders':
        return _json(orders);
      case 'POST /orders':
        final order = _order('PL-12345678', 'PREPARATION', cartQuantity);
        cartQuantity = 0;
        orders.insert(0, order);
        return _json(order, 201);
      case 'GET /loyalty':
        return _json(_summary());
      case 'POST /loyalty/redeem':
        points -= 100;
        wallet += 5;
        movements.insert(0, _movement('Canje de 100 puntos', -100, '5.00'));
        return _json(_summary());
      case 'POST /loyalty/recycling':
        points += 50;
        lifetimePoints += 50;
        movements.insert(0, _movement('Bono Resikla', 50, '0.00'));
        return _json({
          'code': 'RSK-123456',
          'points': 50,
          'summary': _summary(),
        });
      case 'POST /gift-cards':
        return _json({'code': 'GC-ABCD-1234', 'amount': '100.00'}, 201);
      case 'PATCH /me':
        user = {...user, ...body};
        return _json(user);
      case 'GET /content/stores':
        return _json([
          {
            'slug': 'remota',
            'name': 'Tienda remota',
            'district': 'Miraflores',
            'address': 'Av. Larco 123',
            'hours': 'Lun a Dom',
          },
        ]);
      case 'GET /content/blog':
        return _json([
          {
            'slug': 'articulo',
            'title': 'Artículo remoto',
            'category': 'Guías',
            'summary': 'Resumen',
            'body': 'Contenido',
            'imageUrl': 'https://example.com/a.jpg',
            'readMinutes': 2,
            'publishedAt': '2026-01-01T00:00:00.000Z',
          },
        ]);
    }
    if (request.method == 'PATCH' && path.endsWith('/status')) {
      final number = path.split('/')[2];
      final order = orders.firstWhere((o) => o['publicNumber'] == number);
      order['status'] = body['status'];
      return _json(order);
    }
    return _json({'message': 'No encontrado'}, 404);
  }

  Map<String, dynamic> _variant() => {
    'id': _variantId,
    'sku': 'SKU-40',
    'sizeSystem': 'EUR',
    'sizeValue': '40',
    'color': 'Negro',
    'price': '199.90',
    'stock': 3,
  };

  Map<String, dynamic> _product() => {
    'id': _productId,
    'name': 'Producto remoto',
    'slug': 'producto-remoto',
    'description': null,
    'brand': {'name': 'Marca', 'slug': 'marca'},
    'category': {'name': 'Zapatillas', 'slug': 'zapatillas'},
    'images': <Map<String, dynamic>>[],
    'variants': [_variant()],
  };

  List<Map<String, dynamic>> _favorites() => [if (favorite) _product()];

  Map<String, dynamic> _cart() => {
    'items': [
      if (cartQuantity > 0)
        {
          'id': 'item-1',
          'quantity': cartQuantity,
          'variant': {
            ..._variant(),
            'product': {'name': 'Producto remoto', 'slug': 'producto-remoto'},
          },
        },
    ],
    'itemCount': cartQuantity,
  };

  Map<String, dynamic> _order(String number, String status, int quantity) => {
    'publicNumber': number,
    'status': status,
    'paymentMethod': 'WALLET',
    'shipping': '6.90',
    'createdAt': '2026-10-01T15:00:00.000Z',
    'items': [
      {
        'variantId': _variantId,
        'productName': 'Producto remoto',
        'productSlug': 'producto-remoto',
        'image': null,
        'sizeSystem': 'EUR',
        'sizeValue': '40',
        'color': 'Negro',
        'quantity': quantity,
        'unitPrice': '199.90',
      },
    ],
  };

  Map<String, dynamic> _movement(
    String description,
    int points,
    String amount,
  ) => {
    'id': 'movement-${movements.length}',
    'type': points < 0 ? 'REDEMPTION' : 'RECYCLING_BONUS',
    'points': points,
    'walletAmount': amount,
    'description': description,
    'createdAt': '2026-10-02T10:00:00.000Z',
  };

  Map<String, dynamic> _summary() => {
    'points': points,
    'lifetimePoints': lifetimePoints,
    'membership': {'level': 'CLASSIC', 'label': 'Clásica'},
    'walletBalance': wallet.toStringAsFixed(2),
    'movements': movements,
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
    favoritesRepository: FavoritesRepository(client: client),
    ordersRepository: OrdersRepository(client: client),
    accountRepository: AccountRepository(client: client),
    contentRepository: ContentRepository(client: client),
  );
}

Future<void> _settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Matcher _stateError(String message) =>
    throwsA(isA<StateError>().having((e) => e.message, 'message', message));

final _remoteId = 'producto-remoto'.hashCode;
int _size40(Product product) => product.sizes.indexOf('40');

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'el login trae favoritos, pedidos y puntos y sincroniza favoritos',
    () async {
      final backend = _FakeBackend()
        ..favorite = true
        ..orders.add(_FakeBackend()._order('PL-00000001', 'DELIVERED', 1))
        ..points = 206
        ..lifetimePoints = 206;
      final state = _buildState(backend);
      addTearDown(state.dispose);

      await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');

      expect(state.favorites, [_remoteId]);
      expect(state.favoriteProducts.single.remoteId, _productId);
      final order = state.orders.single;
      expect(order.id, 'PL-00000001');
      expect(order.remote, isTrue);
      expect(order.status, OrderStatus.delivered);
      expect(order.total, closeTo(206.8, .001));
      expect(order.items.single.size, '40');
      expect(state.points, 206);

      state.toggleFavorite(_remoteId);
      expect(state.favorites, isEmpty);
      await _settle();
      expect(backend.requests, contains('DELETE /favorites/$_productId'));
      expect(backend.favorite, isFalse);

      backend.failures['PUT /favorites/$_productId'] = (500, 'Error interno');
      state.toggleFavorite(_remoteId);
      await _settle();
      expect(state.favorites, isEmpty);

      state.logout();
      expect(state.orders, isEmpty);
      expect(state.favorites, [1, 3, 4]);
    },
  );

  test('el checkout con sesión crea el pedido en el backend y sincroniza su estado', () async {
    final backend = _FakeBackend();
    final state = _buildState(backend);
    addTearDown(state.dispose);
    await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');
    final product = state.catalogProducts.single;

    state.addToCart(product, _size40(product), SizeSystem.eur);
    final order = await state.checkout(PaymentMethod.wallet);

    expect(
      backend.requests.indexOf('POST /cart/items'),
      lessThan(backend.requests.indexOf('POST /orders')),
    );
    expect(backend.bodies['POST /orders'], {'paymentMethod': 'WALLET'});
    expect(order.id, 'PL-12345678');
    expect(order.remote, isTrue);
    expect(order.total, closeTo(206.8, .001));
    expect(state.cart, isEmpty);
    expect(state.orders.first, order);

    state.advanceOrder(order);
    expect(order.status, OrderStatus.dispatch);
    await _settle();
    expect(backend.bodies['PATCH /orders/PL-12345678/status'], {
      'status': 'DISPATCH',
    });

    backend.failures['PATCH /orders/PL-12345678/status'] = (500, 'Error');
    state.deliverOrder(order);
    expect(order.status, OrderStatus.delivered);
    await _settle();
    expect(order.status, OrderStatus.dispatch);

    await _settle();
    final refreshed = state.catalogProducts.single;
    state.addToCart(refreshed, _size40(refreshed), SizeSystem.eur);
    backend.failures['POST /orders'] = (
      422,
      'El pago con tarjeta no está disponible en la demostración.',
    );
    await expectLater(
      state.checkout(PaymentMethod.card),
      _stateError('El pago con tarjeta no está disponible en la demostración.'),
    );
    expect(state.cart, hasLength(1));
  });

  test(
    'puntos, Resikla, eGift Card y perfil se guardan en el backend',
    () async {
      final backend = _FakeBackend()
        ..points = 150
        ..lifetimePoints = 150;
      final state = _buildState(backend);
      addTearDown(state.dispose);
      await state.loginRemote(email: 'cliente@test.pe', password: 'secreta');

      expect(await state.redeemPoints(), 5.0);
      expect(state.points, 50);
      expect(state.walletBalance, 5.0);
      expect(state.walletMovements.single.description, 'Canje de 100 puntos');

      expect(await state.registerRecycling(), 'RSK-123456');
      expect(state.points, 100);
      expect(state.lifetimePoints, 200);
      backend.failures['POST /loyalty/recycling'] = (
        400,
        'Ya generaste un código Resikla hoy. Vuelve mañana.',
      );
      await expectLater(
        state.registerRecycling(),
        _stateError('Ya generaste un código Resikla hoy. Vuelve mañana.'),
      );

      final code = await state.sendGiftCard(
        amount: 100,
        recipientName: 'Ana Pérez',
        recipientEmail: 'ana@test.pe',
      );
      expect(code, 'GC-ABCD-1234');
      expect(backend.bodies['POST /gift-cards'], {
        'amount': 100,
        'recipientName': 'Ana Pérez',
        'recipientEmail': 'ana@test.pe',
      });

      await state.saveProfile(
        AppUser(
          name: 'Cliente Editado',
          document: state.user.document,
          email: 'cliente@test.pe',
          phone: '987654321',
        ),
      );
      expect(state.user.name, 'Cliente Editado');
      expect(state.user.phone, '987654321');

      backend.failures['PATCH /me'] = (409, 'No se pudo actualizar el correo.');
      await expectLater(
        state.saveProfile(
          AppUser(
            name: 'Cliente Editado',
            document: '',
            email: 'otro@test.pe',
            phone: '987654321',
          ),
        ),
        _stateError('No se pudo actualizar el correo.'),
      );
      expect(state.user.email, 'cliente@test.pe');

      backend.failures['POST /gift-cards'] = (
        500,
        'PrismaClientKnownRequestError',
      );
      await expectLater(
        state.sendGiftCard(
          amount: 50,
          recipientName: 'Ana Pérez',
          recipientEmail: 'ana@test.pe',
        ),
        _stateError(
          'El sistema está fallando en este momento. Intenta más tarde.',
        ),
      );
    },
  );

  test(
    'tiendas y blog llegan desde /content y conservan los de ejemplo si falla',
    () async {
      final backend = _FakeBackend();
      final state = _buildState(backend);
      addTearDown(state.dispose);
      await state.loadContent();
      expect(state.storeLocations.single.name, 'Tienda remota');
      expect(state.articles.single.title, 'Artículo remoto');

      final failing = _FakeBackend()
        ..failures['GET /content/blog'] = (500, 'Error interno');
      final fallback = _buildState(failing);
      addTearDown(fallback.dispose);
      await fallback.loadContent();
      expect(fallback.storeLocations, hasLength(stores.length));
      expect(fallback.articles, hasLength(blogArticles.length));
    },
  );
}
