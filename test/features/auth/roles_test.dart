import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/app/app.dart';
import 'package:platanitos_app/app/models/shop_models.dart';
import 'package:platanitos_app/app/state/shop_state.dart';
import 'package:platanitos_app/features/administration/presentation/screens/role_home.dart';
import 'package:platanitos_app/app/shop_shell.dart';
import 'package:platanitos_app/app/data/memory_demo_store.dart';
import 'package:platanitos_app/features/inventory/presentation/screens/inventory_screen.dart';

void main() {
  testWidgets('administrative account opens its panel', (tester) async {
    final state = ShopState()
      ..login(
        account: const AppUser(
          name: 'Admin',
          document: '',
          email: 'admin@example.com',
          phone: '',
          role: UserRole.administrativo,
        ),
      );
    addTearDown(state.dispose);
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.pump();
    expect(find.byType(AdministrativeHome), findsOneWidget);
    expect(find.text('Panel administrativo'), findsOneWidget);
    expect(find.byType(ShopShell), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('applicant account keeps access to the shop', (tester) async {
    final state = ShopState()
      ..login(
        account: const AppUser(
          name: 'Postulante',
          document: '',
          email: 'postulante@example.com',
          phone: '',
        ),
      );
    addTearDown(state.dispose);
    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.pump();
    expect(find.byType(ShopShell), findsOneWidget);
    expect(find.byType(AdministrativeHome), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('demo profile opens the warehouse inventory', (tester) async {
    final store = DemoMemoryStore();
    final state = ShopState(
      demoAuthRepository: MemoryDemoAuthRepository(store),
      catalogRepository: MemoryCatalogRepository(store),
      inventoryRepository: MemoryInventoryRepository(store),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un perfil'), findsOneWidget);

    await tester.tap(find.text('Almacén'));
    await tester.pumpAndSettle();
    expect(find.text('Gestión de almacén'), findsOneWidget);
    expect(find.byType(InventoryScreen), findsOneWidget);
    expect(find.text('Zapatilla Plataforma'), findsWidgets);
  });

  testWidgets('client profile requests credentials before opening the shop', (
    tester,
  ) async {
    final store = DemoMemoryStore();
    final state = ShopState(
      demoAuthRepository: MemoryDemoAuthRepository(store),
      catalogRepository: MemoryCatalogRepository(store),
      inventoryRepository: MemoryInventoryRepository(store),
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(PlatanitosApp(state: state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión como Cliente'), findsOneWidget);
    expect(find.text('Correo: cliente@demo.local'), findsOneWidget);
    expect(find.text('Contraseña: Cliente123'), findsOneWidget);
    expect(state.signedIn, isFalse);

    await tester.enterText(find.byType(TextFormField).at(1), 'Cliente123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(state.signedIn, isTrue);
    expect(state.user.role, UserRole.cliente);
    expect(find.byType(ShopShell), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
