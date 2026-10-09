import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../shared/state/shop_state.dart';
import '../widgets/line_icons.dart';
import '../widgets/shop_widgets.dart';
import '../features/account/presentation/account_screens.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/catalog/presentation/catalog_screens.dart';
import '../features/orders/presentation/order_screens.dart';

class ShopShell extends StatefulWidget {
  const ShopShell({super.key});
  @override
  State<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends State<ShopShell> {
  int tab = 0;
  void select(int value) => setState(() => tab = value);
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final titles = ['Inicio', 'Categorías', 'Mi Bolsa', 'Favoritos', 'Mi Cuenta'];
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) select(0);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: tab == 0
              ? null
              : IconButton(
                  tooltip: 'Volver al inicio',
                  onPressed: () => select(0),
                  icon: const LineIcon(LineIcons.back),
                ),
          title: tab == 0 ? const BrandLogo(fontSize: 26) : Text(titles[tab]),
          centerTitle: tab != 0,
          titleSpacing: tab == 0 ? 16 : null,
          actions: [
            if (tab == 0)
              IconButton(
                tooltip: 'Notificaciones y pedidos',
                onPressed: () => openWithLogin(
                  context,
                  AuthPrompt.orders,
                  (_) => const OrdersScreen(),
                ),
                icon: const LineIcon(LineIcons.bell),
              ),
            IconButton(
              tooltip: 'Ver bolsa',
              onPressed: () => select(2),
              icon: Badge(
                isLabelVisible: state.cartCount > 0,
                label: Text('${state.cartCount}'),
                child: const LineIcon(LineIcons.bag),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: IndexedStack(
                index: tab,
                children: [
                  HomeScreen(onCatalog: () => select(1)),
                  const CategoriesScreen(),
                  CartScreen(onCatalog: () => select(1)),
                  FavoritesScreen(onCatalog: () => select(1)),
                  AccountScreen(onFavorites: () => select(3)),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 64,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.darkGreen
                      : AppColors.ink,
                ),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: 24,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.darkGreen
                      : AppColors.ink,
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: select,
              destinations: const [
                NavigationDestination(
                  icon: LineIcon(LineIcons.home),
                  label: 'Inicio',
                ),
                NavigationDestination(
                  icon: LineIcon(LineIcons.grid),
                  label: 'Categorías',
                ),
                NavigationDestination(
                  icon: LineIcon(LineIcons.bag),
                  label: 'Bolsa',
                ),
                NavigationDestination(
                  icon: LineIcon(LineIcons.heart),
                  label: 'Favoritos',
                ),
                NavigationDestination(
                  icon: LineIcon(LineIcons.user),
                  label: 'Mi Cuenta',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
