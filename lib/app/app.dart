import 'dart:async';

import 'package:flutter/material.dart';

import '../core/config/app_environment.dart';
import '../core/theme/app_theme.dart';
import './dependencies.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/administration/presentation/screens/role_home.dart';
import './state/shop_state.dart';

class PlatanitosApp extends StatefulWidget {
  const PlatanitosApp({super.key, this.state});
  final ShopState? state;
  @override
  State<PlatanitosApp> createState() => _PlatanitosAppState();
}

class _PlatanitosAppState extends State<PlatanitosApp> {
  ShopState? state;
  AppDependencies? dependencies;
  Object? initializationError;
  bool restoring = true;

  @override
  void initState() {
    super.initState();
    if (widget.state != null) {
      state = widget.state;
      restoring = false;
    } else {
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    try {
      final createdDependencies = await AppDependencies.create();
      final createdState = ShopState(
        seedHistory: createdDependencies.mode == AppMode.demo,
        catalogRepository: createdDependencies.catalog,
        authRepository: createdDependencies.auth,
        demoAuthRepository: createdDependencies.demoAuth,
        inventoryRepository: createdDependencies.inventory,
        operationsRepository: createdDependencies.operations,
        tokenStore: createdDependencies.tokenStore,
        cartRepository: createdDependencies.cart,
        favoritesRepository: createdDependencies.favorites,
        ordersRepository: createdDependencies.orders,
        loyaltyRepository: createdDependencies.loyalty,
        giftCardsRepository: createdDependencies.giftCards,
        contentRepository: createdDependencies.content,
        addressesRepository: createdDependencies.addresses,
      );
      await createdState.restoreSession();
      unawaited(createdState.loadContent());
      if (!mounted) {
        createdState.dispose();
        await createdDependencies.dispose();
        return;
      }
      setState(() {
        dependencies = createdDependencies;
        state = createdState;
        restoring = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        initializationError = error;
        restoring = false;
      });
    }
  }

  @override
  void dispose() {
    if (widget.state == null) state?.dispose();
    unawaited(dependencies?.dispose());
    super.dispose();
  }

  Widget _materialApp(Widget home, {required ShopState state}) => MaterialApp(
    title: 'Platanitos',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    builder: (context, child) => ListenableBuilder(
      listenable: state,
      builder: (context, _) => Theme(
        data: buildTheme(highContrast: state.highContrast),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
    home: home,
  );

  @override
  Widget build(BuildContext context) {
    if (restoring) {
      return _materialApp(
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    final currentState = state;
    if (currentState == null) {
      return _materialApp(
        Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('No se pudo iniciar el almacenamiento local.'),
                  const SizedBox(height: 8),
                  Text('$initializationError', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        restoring = true;
                        initializationError = null;
                      });
                      unawaited(_initialize());
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ShopScope(
      state: currentState,
      child: _materialApp(
        currentState.signedIn ? const RoleHome() : const LoginScreen(),
        state: currentState,
      ),
    );
  }
}
