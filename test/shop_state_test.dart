import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/data/mock_data.dart';
import 'package:platanitos_app/shared/models/shop_models.dart';
import 'package:platanitos_app/shared/state/shop_state.dart';
import 'package:platanitos_app/core/validators.dart';

void main() {
  test('Cart retains separate products and sizes and merges equivalent size systems', () {
    final state = ShopState(seedHistory: false);
    addTearDown(state.dispose);
    state.addToCart(products[0], 2, SizeSystem.eur);
    state.addToCart(products[1], 3, SizeSystem.us);
    state.addToCart(products[0], 2, SizeSystem.cm);
    state.addToCart(products[0], 1, SizeSystem.eur);
    expect(state.cart.length, 3);
    expect(state.cart.first.quantity, 2);
    expect(state.cart.first.size, '37');
    expect(state.subtotal, closeTo(429.6, .001));
    expect(state.total, closeTo(436.5, .001));
    state.changeQuantity(state.cart.first, -1);
    expect(state.cartCount, 3);
    state.removeItem(state.cart[1]);
    expect(state.total, closeTo(186.7, .001));
    expect(
      () => state.addToCart(products[0], -1, SizeSystem.eur),
      throwsArgumentError,
    );
  });
  test(
    'Checkout snapshots cart and retains unique orders through delivery',
    () {
      final state = ShopState(seedHistory: false);
      addTearDown(state.dispose);
      state.addToCart(products[0], 2, SizeSystem.eur);
      final order = state.placeOrder(PaymentMethod.cash);
      expect(order.payment, PaymentMethod.cash);
      expect(order.total, closeTo(96.8, .001));
      expect(state.cart, isEmpty);
      expect(state.shipping, 0);
      state.addToCart(products[2], 4, SizeSystem.us);
      state.changeQuantity(state.cart.first, 2);
      expect(order.items.first.quantity, 1);
      final second = state.placeOrder(PaymentMethod.wallet);
      expect(second.id, isNot(order.id));
      state.advanceOrder(order);
      expect(order.status, OrderStatus.dispatch);
      state.deliverOrder(order);
      expect(
        state.orders.where((o) => o.status == OrderStatus.delivered),
        contains(order),
      );
      expect(() => state.placeOrder(PaymentMethod.wallet), throwsStateError);
    },
  );
  test('Favorites share one state and filters combine search, brand, color and price', () {
    final state = ShopState();
    addTearDown(state.dispose);
    state.toggleFavorite(2);
    expect(state.favorites, contains(2));
    state.toggleFavorite(2);
    expect(state.favorites, isNot(contains(2)));
    final filter = CatalogFilter()
      ..query = 'platanitos'
      ..colors.add('Blanco')
      ..price = PriceRange.all.first;
    expect(filter.apply(products).single.id, 1);
    filter.colors
      ..clear()
      ..add('Negro');
    expect(filter.apply(products), isEmpty);
    filter.clear();
    filter.sort = ProductSort.cheapest;
    expect(filter.apply(products).first.id, 4);
  });
  test(
    'Purchases and recycling earn points that redeem into the wallet',
    () async {
      final state = ShopState();
      addTearDown(state.dispose);
      expect(state.lifetimePoints, 86);
      await expectLater(state.redeemPoints(), throwsStateError);
      expect(await state.registerRecycling(), startsWith('RSK-'));
      expect(state.points, 136);
      expect(await state.redeemPoints(), 5.0);
      expect(state.walletBalance, 5.0);
      expect(state.walletMovements.single.description, 'Canje de 100 puntos');
      expect(state.points, 36);
      expect(state.lifetimePoints, 136);
      expect(state.membership, MembershipLevel.classic);
      expect(MembershipLevel.forPoints(300), MembershipLevel.silver);
      expect(MembershipLevel.forPoints(1200), MembershipLevel.gold);
      expect(MembershipLevel.gold.next, isNull);
    },
  );
  test('Registration validates Peruvian document and phone', () {
    expect(Validators.document('12345678', 'DNI'), isNull);
    expect(Validators.document('123', 'DNI'), isNotNull);
    expect(Validators.phone('987654321'), isNull);
    expect(Validators.phone('187654321'), isNotNull);
    expect(Validators.email('invalid'), isNotNull);
    expect(Validators.name('Daniela Rojas'), isNull);
  });
}
