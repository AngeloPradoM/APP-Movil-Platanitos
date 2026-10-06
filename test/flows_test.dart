import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/core/app_theme.dart';
import 'package:platanitos_app/main.dart';
import 'package:platanitos_app/models/shop_models.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/state/shop_state.dart';
import 'package:platanitos_app/screens/checkout_screen.dart';
import 'package:platanitos_app/screens/account_screens.dart';
import 'package:platanitos_app/screens/auth_screens.dart';

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Future<void> mount(WidgetTester tester, ShopState state, Widget page) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ShopScope(
      state: state,
      child: MaterialApp(theme: buildTheme(), home: page),
    ),
  );
}

void main() {
  testWidgets(
    'Card error can switch method without losing cart and cash completes',
    (tester) async {
      final state = ShopState(seedHistory: false)
        ..addToCart(products[1], 3, SizeSystem.eur);
      addTearDown(state.dispose);
      await mount(tester, state, const CheckoutScreen());
      await tester.tap(find.text('Tarjeta de Crédito / Débito'));
      await tester.pump();
      expect(
        tester.widget<TextField>(field('Número de tarjeta de prueba')).readOnly,
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Pagar S/ 166.80'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pagar S/ 166.80'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('No pudimos procesar tu pago.'), findsOneWidget);
      expect(state.orders, isEmpty);
      expect(state.cartCount, 1);
      await tester.tap(find.text('Cambiar método de pago'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Pago en Efectivo (Agentes)'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pago en Efectivo (Agentes)'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Pagar S/ 166.80'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Pagar S/ 166.80'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(state.orders.single.payment, PaymentMethod.cash);
      expect(state.cart, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Profile edits validate and persist in shared user', (
    tester,
  ) async {
    final state = ShopState();
    addTearDown(state.dispose);
    await mount(tester, state, const ProfileScreen());
    await tester.ensureVisible(find.text('Editar datos'));
    await tester.tap(find.text('Editar datos'));
    await tester.pump();
    await tester.enterText(field('Nombre'), 'María Torres');
    await tester.enterText(field('Correo'), 'maria@example.com');
    await tester.scrollUntilVisible(
      field('Teléfono'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field('Teléfono'), '912345678');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pump();
    expect(state.user.name, 'María Torres');
    expect(state.user.email, 'maria@example.com');
    expect(state.user.phone, '912345678');
    expect(find.text('Datos actualizados correctamente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });
  testWidgets(
    'Home search reaches catalog and clearing filters synchronizes search text',
    (tester) async {
      final state = ShopState()..login();
      addTearDown(state.dispose);
      await tester.pumpWidget(PlatanitosApp(state: state));
      await tester.enterText(find.byType(TextField).first, 'Botines');
      await tester.tap(find.byTooltip('Buscar').first);
      await tester.pump();
      expect(find.text('Resultados para “Botines”'), findsOneWidget);
      expect(find.text('1 productos'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'noexiste');
      await tester.pump();
      await tester.ensureVisible(find.text('Limpiar búsqueda y filtros'));
      await tester.tap(find.text('Limpiar búsqueda y filtros'));
      await tester.pump();
      expect(state.catalog.query, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Recovery validates email and simulates resend', (tester) async {
    final state = ShopState();
    addTearDown(state.dispose);
    await mount(tester, state, const RecoveryScreen());
    await tester.enterText(field('Correo electrónico'), 'cliente@example.com');
    await tester.tap(find.text('Enviar enlace de recuperación'));
    await tester.pump();
    expect(find.text('Revisa tu correo'), findsOneWidget);
    await tester.tap(find.text('Enviar nuevamente'));
    await tester.pump();
    expect(field('Correo electrónico'), findsOneWidget);
  });
}
