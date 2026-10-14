import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/app/data/memory_demo_store.dart';
import 'package:platanitos_app/app/state/shop_state.dart';
import 'package:platanitos_app/core/theme/app_theme.dart';
import 'package:platanitos_app/features/administration/presentation/screens/role_home.dart';
import 'package:platanitos_app/features/auth/domain/user_models.dart';
import 'package:platanitos_app/features/delivery/presentation/screens/delivery_evidence_dialog.dart';
import 'package:platanitos_app/features/fulfillment/presentation/screens/fulfillment_screen.dart';
import 'package:platanitos_app/features/operations/data/memory_demo_operations_repository.dart';
import 'package:platanitos_app/features/support/presentation/screens/support_dashboard.dart';

void main() {
  const scenarios = <UserRole, String>{
    UserRole.almacen: 'Gestión de almacén',
    UserRole.repartidor: 'Panel del repartidor',
    UserRole.atencionCliente: 'Atención al cliente',
    UserRole.administrador: 'Panel administrativo',
    UserRole.trabajadorTienda: 'Trabajador de tienda',
  };

  for (final scenario in scenarios.entries) {
    testWidgets(
      '${scenario.key.name} remains usable at 320 px with enlarged text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final store = DemoMemoryStore();
        final profile = DemoMemoryStore.profiles.firstWhere(
          (user) => user.role == scenario.key,
        );
        final state = ShopState(
          seedHistory: false,
          demoAuthRepository: MemoryDemoAuthRepository(store),
          catalogRepository: MemoryCatalogRepository(store),
          inventoryRepository: MemoryInventoryRepository(store),
          operationsRepository: MemoryDemoOperationsRepository(store),
        )..login(account: profile);
        addTearDown(state.dispose);

        await tester.pumpWidget(
          ShopScope(
            state: state,
            child: MaterialApp(
              theme: buildTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: const RoleHome(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(scenario.value), findsAtLeastNWidgets(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fulfillment refreshes immediately after changing status', (
    tester,
  ) async {
    final store = DemoMemoryStore();
    final operations = MemoryDemoOperationsRepository(store);
    await operations.setCartItem('demo-cliente', 'product-1-36-blanco', 1);
    await operations.checkout(
      userId: 'demo-cliente',
      paymentMethod: 'WALLET',
      shippingCents: 690,
      address: 'Av. Demo 123',
    );
    final state = ShopState(
      seedHistory: false,
      operationsRepository: operations,
    )..login(account: DemoMemoryStore.profiles[1]);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      ShopScope(
        state: state,
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: FulfillmentScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('En preparación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('support request refreshes without signing in again', (
    tester,
  ) async {
    final store = DemoMemoryStore();
    final operations = MemoryDemoOperationsRepository(store);
    await operations.setCartItem('demo-cliente', 'product-1-36-blanco', 1);
    final order = await operations.checkout(
      userId: 'demo-cliente',
      paymentMethod: 'WALLET',
      shippingCents: 690,
      address: 'Av. Demo 123',
    );
    await operations.createSupportRequest(
      orderId: order.id,
      userId: 'demo-cliente',
      type: 'CHANGE',
      reason: 'Necesito otra talla',
    );
    final state = ShopState(
      seedHistory: false,
      operationsRepository: operations,
    )..login(account: DemoMemoryStore.profiles[3]);
    addTearDown(state.dispose);

    await tester.pumpWidget(
      ShopScope(
        state: state,
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: SupportDashboard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atender'));
    await tester.pumpAndSettle();

    expect(find.textContaining('En revisión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid stored signature has a safe fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: const Scaffold(
          body: DeliverySignaturePreview(data: 'firma-invalida'),
        ),
      ),
    );

    expect(find.text('Firma no disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
