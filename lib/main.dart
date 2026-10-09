import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/app_dependencies.dart';
import 'features/auth/presentation/auth_screens.dart';
import 'app/shop_shell.dart';
import 'shared/state/shop_state.dart';

void main() => runApp(const PlatanitosApp());

class PlatanitosApp extends StatefulWidget {
  const PlatanitosApp({super.key, this.state});
  final ShopState? state;
  @override
  State<PlatanitosApp> createState() => _PlatanitosAppState();
}

class _PlatanitosAppState extends State<PlatanitosApp> {
  late final ShopState state;
  bool restoring = false;

  @override
  void initState() {
    super.initState();
    final dependencies = AppDependencies.local();
    state =
        widget.state ??
        ShopState(
          catalogRepository: dependencies.catalog,
          authRepository: dependencies.auth,
          cartRepository: dependencies.cart,
          favoritesRepository: dependencies.favorites,
          ordersRepository: dependencies.orders,
          accountRepository: dependencies.account,
          contentRepository: dependencies.content,
        );
    state.restoreSession().whenComplete(() {
      if (mounted) setState(() {});
    });
    state.loadContent();
  }

  @override
  void dispose() {
    if (widget.state == null) state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShopScope(
    state: state,
    child: MaterialApp(
      title: 'Platanitos',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: restoring
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (state.signedIn ? const ShopShell() : const LoginScreen()),
    ),
  );
}
