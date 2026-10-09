import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:platanitos_app/core/app_theme.dart';
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/features/catalog/data/catalog_repository.dart';
import 'package:platanitos_app/features/catalog/presentation/product_screen.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

const _main = 'https://images.unsplash.com/photo-1?fit=crop&q=85&w=800';
final _detailImages = [
  for (var i = 0; i < 5; i++) 'https://example.com/foto-$i.jpg',
];

class _DetailBackend extends http.BaseClient {
  int requests = 0;
  bool fail = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    if (fail) return _json({'message': 'error'}, 500);
    return _json({
      'id': 'product-uuid',
      'name': 'Cartera remota',
      'slug': 'cartera-remota',
      'description': null,
      'brand': {'name': 'Marca', 'slug': 'marca'},
      'category': {'name': 'Carteras', 'slug': 'carteras'},
      'images': [
        for (final url in _detailImages) {'url': url},
      ],
      'variants': [
        {
          'id': 'variant-uuid',
          'sizeSystem': 'ONE_SIZE',
          'sizeValue': 'Única',
          'color': 'Negro',
          'price': '119.90',
          'stock': 4,
        },
      ],
    });
  }

  http.StreamedResponse _json(Object payload, [int status = 200]) =>
      http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(payload))),
        status,
        headers: {'content-type': 'application/json'},
      );
}

const _listed = Product(
  id: 1,
  remoteId: 'product-uuid',
  slug: 'cartera-remota',
  images: [_main],
  brand: 'MARCA',
  name: 'Cartera remota',
  category: 'Carteras',
  price: 119.9,
  oldPrice: 119.9,
  image: _main,
  color: 'Negro',
  sizeSystem: SizeSystem.oneSize,
  sizes: ['Única'],
  availableSizes: [0],
);

ShopState _buildState(_DetailBackend backend) => ShopState(
  seedHistory: false,
  catalogRepository: CatalogRepository(
    client: ApiClient(baseUrl: 'http://test', client: backend),
  ),
);

void main() {
  test('una foto de Unsplash genera vistas de detalle; otras no', () {
    expect(_listed.gallery, [
      _main,
      '$_main&flip=h',
      '$_main&crop=focalpoint&fp-x=0.42&fp-y=0.55&fp-z=1.8',
      '$_main&crop=focalpoint&fp-x=0.6&fp-y=0.45&fp-z=2.3',
    ]);
    const plain = Product(
      id: 2,
      brand: 'MARCA',
      name: 'Sin galería',
      category: 'Otros',
      price: 10,
      oldPrice: 10,
      image: 'https://example.com/a.jpg',
      color: 'Negro',
    );
    expect(plain.gallery, ['https://example.com/a.jpg']);
  });

  test(
    'carga la galería completa una vez y vuelve a lo local si falla',
    () async {
      final backend = _DetailBackend();
      final state = _buildState(backend);
      addTearDown(state.dispose);

      expect(await state.loadGallery(_listed), _detailImages);
      expect(await state.loadGallery(_listed), _detailImages);
      expect(state.galleryOf(_listed), _detailImages);
      expect(backend.requests, 1);

      final failing = _DetailBackend()..fail = true;
      final offline = _buildState(failing);
      addTearDown(offline.dispose);
      expect(await offline.loadGallery(_listed), _listed.gallery);
    },
  );

  testWidgets('el detalle muestra las fotos del producto con miniaturas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = _buildState(_DetailBackend());
    addTearDown(state.dispose);

    await tester.pumpWidget(
      ShopScope(
        state: state,
        child: MaterialApp(
          theme: buildTheme(),
          home: const ProductScreen(product: _listed),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.bySemanticsLabel('Ver foto 1 de 5'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Ver foto 3 de 5'));
    await tester.pumpAndSettle();
    final page = tester.widget<PageView>(find.byType(PageView));
    expect(page.controller!.page, 2);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
