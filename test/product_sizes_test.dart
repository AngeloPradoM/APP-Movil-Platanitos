import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/core/app_theme.dart';
import 'package:platanitos_app/features/catalog/presentation/product_screen.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';

const _shirt = Product(
  id: 501,
  brand: 'MARCA',
  name: 'Polo básico',
  category: 'Polos',
  price: 49.9,
  oldPrice: 69.9,
  image: '',
  color: 'Azul',
  sizeSystem: SizeSystem.alpha,
  sizes: ['S', 'M', 'L', 'XL'],
  availableSizes: [0, 1, 3],
);

const _bag = Product(
  id: 502,
  brand: 'MARCA',
  name: 'Cartera de mano',
  category: 'Carteras',
  price: 119.9,
  oldPrice: 119.9,
  image: '',
  color: 'Negro',
  sizeSystem: SizeSystem.oneSize,
  sizes: ['Única'],
  availableSizes: [0],
);

const _babyShoes = Product(
  id: 503,
  brand: 'MARCA',
  name: 'Body bebé',
  category: 'Bebés',
  price: 29.9,
  oldPrice: 29.9,
  image: '',
  color: 'Celeste',
  sizeSystem: SizeSystem.alpha,
  sizes: ['0-3M', '3-6M', '6-12M', '12-18M'],
  availableSizes: [0, 1, 2, 3],
);

Future<ShopState> _open(WidgetTester tester, Product product) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = ShopState(seedHistory: false);
  addTearDown(state.dispose);
  await tester.pumpWidget(
    ShopScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme(),
        home: ProductScreen(product: product),
      ),
    ),
  );
  await tester.pump();
  return state;
}

void main() {
  testWidgets('ALPHA muestra S/M/L/XL sin conversor EUR/US/CM', (tester) async {
    final state = await _open(tester, _shirt);

    expect(find.text('US'), findsNothing);
    expect(find.text('-29%'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('XL'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('M'));
    await tester.pump();
    await tester.tap(find.text('Agregar a la Bolsa'));
    await tester.pump();

    expect(state.cart.single.size, 'M');
    expect(state.cart.single.sizeText, 'Talla M');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('ONE_SIZE se agrega sin elegir talla', (tester) async {
    final state = await _open(tester, _bag);

    expect(find.text('Guía de tallas'), findsNothing);
    expect(find.text('EUR'), findsNothing);
    await tester.tap(find.text('Agregar a la Bolsa'));
    await tester.pump();

    expect(state.cart.single.sizeText, 'Talla única');
    expect(state.cart.single.system, SizeSystem.oneSize);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('tallas largas caben a 320 px con texto ampliado', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, _babyShoes);
    await tester.scrollUntilVisible(
      find.text('12-18M'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
