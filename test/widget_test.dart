import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/main.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';

void main() {
  testWidgets('Login rejects invalid values and password visibility toggles', (
    tester,
  ) async {
    await tester.pumpWidget(const PlatanitosApp());
    await tester.tap(find.text('Iniciar sesión').last);
    await tester.pump();
    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('Usa al menos 8 caracteres.'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });
  testWidgets('Product requires size and keeps selected US size in cart', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = ShopState()..login();
    addTearDown(state.dispose);
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('Zapatilla Plataforma').first,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zapatilla Plataforma').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Agregar a la Bolsa'));
    await tester.pump();
    expect(state.cart, isEmpty);
    expect(
      find.text('Selecciona una talla antes de agregar a la bolsa.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('EUR'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('US'));
    await tester.pump();
    await tester.tap(find.text('7'));
    await tester.tap(find.text('Agregar a la Bolsa'));
    await tester.pump();
    expect(state.cart.single.size, '7');
    expect(state.cart.single.system, SizeSystem.us);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
  testWidgets('Wallet checkout creates order and clears bag', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = ShopState(seedHistory: false)
      ..login()
      ..addToCart(products[0], 2, SizeSystem.eur);
    addTearDown(state.dispose);
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.tap(find.text('Bolsa'));
    await tester.pump();
    await tester.tap(find.text('Ir a Pagar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('Pagar S/ 96.80'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pagar S/ 96.80'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.orders.length, 1);
    expect(state.cart, isEmpty);
    expect(find.text('¡Gracias por tu compra!'), findsOneWidget);
    expect(find.text('#${state.orders.single.id}'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
