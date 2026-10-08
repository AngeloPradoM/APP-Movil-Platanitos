import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../shared/state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import '../features/account/presentation/account_screens.dart';
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
    final titles = ['Inicio', 'Calzado', 'Mi Bolsa', 'Favoritos', 'Mi Cuenta'];
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) select(0);
      },
      child: Scaffold(
        appBar: AppBar(
          title: tab == 0 ? const BrandLogo() : Text(titles[tab]),
          centerTitle: tab != 0,
          actions: [
            if (tab == 0)
              IconButton(
                tooltip: 'Notificaciones y pedidos',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
                ),
                icon: const Badge(
                  smallSize: 6,
                  backgroundColor: AppColors.yellow,
                  child: Icon(Icons.notifications_outlined),
                ),
              ),
            IconButton(
              tooltip: 'Ver bolsa',
              onPressed: () => select(2),
              icon: Badge(
                isLabelVisible: state.cartCount > 0,
                label: Text('${state.cartCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
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
                  const CatalogScreen(),
                  CartScreen(onCatalog: () => select(1)),
                  FavoritesScreen(onCatalog: () => select(1)),
                  AccountScreen(onFavorites: () => select(3)),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: select,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.softGreen,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.green),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              label: 'Categorías',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Bolsa',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Mi cuenta',
            ),
          ],
        ),
      ),
    );
  }
}
