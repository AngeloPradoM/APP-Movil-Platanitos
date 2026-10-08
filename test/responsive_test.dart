import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/core/app_theme.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';
import 'package:platanitos_app/features/auth/presentation/auth_screens.dart';
import 'package:platanitos_app/features/catalog/presentation/catalog_screens.dart';
import 'package:platanitos_app/features/cart/presentation/cart_screen.dart';
import 'package:platanitos_app/features/checkout/presentation/checkout_screen.dart';
import 'package:platanitos_app/features/orders/presentation/order_screens.dart';
import 'package:platanitos_app/features/account/presentation/account_screens.dart';
import 'package:platanitos_app/features/support/presentation/support_screens.dart';
import 'package:platanitos_app/features/catalog/presentation/product_screen.dart';
import 'package:platanitos_app/widgets/shop_widgets.dart';

void main() {
  for (final width in [320.0, 430.0, 900.0]) {
    testWidgets('All 18 screens fit width $width with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = ShopState()
        ..login()
        ..addToCart(products[0], 2, SizeSystem.eur);
      addTearDown(state.dispose);
      final order = state.orders.first;
      final screens = <Widget>[
        const LoginScreen(),
        const RecoveryScreen(),
        const SignupScreen(),
        PageFrame(
          title: 'Inicio',
          child: HomeScreen(onCatalog: () {}),
        ),
        const PageFrame(title: 'Calzado', child: CatalogScreen()),
        ProductScreen(product: products[0]),
        PageFrame(
          title: 'Mi Bolsa',
          child: CartScreen(onCatalog: () {}),
        ),
        PageFrame(
          title: 'Favoritos',
          child: FavoritesScreen(onCatalog: () {}),
        ),
        const CheckoutScreen(),
        SuccessScreen(order: order),
        TrackingScreen(order: order),
        DeliveryScreen(order: order),
        DeliveredScreen(order: order),
        const OrdersScreen(),
        PageFrame(
          title: 'Mi Cuenta',
          child: AccountScreen(onFavorites: () {}),
        ),
        const ProfileScreen(),
        const SupportScreen(),
        const OfflineScreen(),
      ];
      for (var index = 0; index < screens.length; index++) {
        await tester.pumpWidget(
          ShopScope(
            state: state,
            child: MaterialApp(
              key: ValueKey(index),
              theme: buildTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: screens[index],
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Screen $index ${screens[index].runtimeType} at width $width',
        );
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -650));
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason:
                'Scrolled $index ${screens[index].runtimeType} at width $width',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
