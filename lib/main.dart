import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/auth_screens.dart';
import 'screens/shop_shell.dart';
import 'state/shop_state.dart';

void main() => runApp(const PlatanitosApp());

class PlatanitosApp extends StatefulWidget {
  const PlatanitosApp({super.key, this.state});
  final ShopState? state;
  @override
  State<PlatanitosApp> createState() => _PlatanitosAppState();
}

class _PlatanitosAppState extends State<PlatanitosApp> {
  late final ShopState state = widget.state ?? ShopState();
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
      home: state.signedIn ? const ShopShell() : const LoginScreen(),
    ),
  );
}
