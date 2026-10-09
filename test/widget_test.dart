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
    await tester.tap(find.text('Iniciar Sesión'));
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
  testWidgets('Guest bag requires login before checkout and keeps items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = ShopState(seedHistory: false)
      ..addToCart(products[0], 2, SizeSystem.eur);
    addTearDown(state.dispose);
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.ensureVisible(find.text('Continuar como invitada/o'));
    await tester.tap(find.text('Continuar como invitada/o'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.signedIn, isFalse);
    await tester.tap(find.text('Bolsa'));
    await tester.pump();
    await tester.tap(find.text('Ir a Pagar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Inicia sesión para pagar'), findsOneWidget);
    expect(find.text('Continuar como invitada/o'), findsNothing);
    expect(find.text('Dirección de envío'), findsNothing);
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == label,
    );
    await tester.enterText(field('ejemplo@correo.com'), 'cliente@example.com');
    await tester.enterText(field('Ingresa tu contraseña'), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.signedIn, isTrue);
    expect(find.text('Dirección de envío'), findsOneWidget);
    expect(state.cartCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Guest account invites login and private sections require it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = ShopState(seedHistory: false);
    addTearDown(state.dispose);
    final favoritesBefore = state.favorites;
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.ensureVisible(find.text('Continuar como invitada/o'));
    await tester.tap(find.text('Continuar como invitada/o'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Categorías'));
    await tester.pump();
    await tester.tap(find.text(products[0].name).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Cambiar favorito'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Inicia sesión para guardar favoritos'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.favorites, favoritesBefore);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Mi Cuenta'));
    await tester.pump();
    expect(find.text('Hola, invitada/o'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
    await tester.ensureVisible(find.text('Monedero'));
    await tester.tap(find.text('Monedero'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Inicia sesión para continuar'), findsOneWidget);
    Finder field(String label) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == label,
    );
    await tester.enterText(field('ejemplo@correo.com'), 'cliente@example.com');
    await tester.enterText(field('Ingresa tu contraseña'), 'secreta123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.signedIn, isTrue);
    expect(find.text('Saldo disponible'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Hola, invitada/o'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
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
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.tap(find.text('Continuar al pago'));
    await tester.pump();
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
