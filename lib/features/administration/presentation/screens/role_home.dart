import 'package:flutter/material.dart';

import '../../../../app/shop_shell.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_guide_dialog.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../auth/domain/user_models.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../delivery/presentation/screens/delivery_dashboard.dart';
import '../../../fulfillment/presentation/screens/fulfillment_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../store_operations/presentation/screens/store_operations_screen.dart';
import '../../../support/presentation/screens/support_dashboard.dart';
import 'operations_admin_dashboard.dart';

class RoleHome extends StatelessWidget {
  const RoleHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    if (!state.signedIn) return const ShopShell();
    return switch (state.user.role) {
      UserRole.cliente => const ShopShell(),
      UserRole.almacen => const _RoleScaffold(
        title: 'Gestión de almacén',
        child: _WarehouseHome(),
      ),
      UserRole.repartidor => const _RoleScaffold(
        title: 'Panel del repartidor',
        child: DeliveryDashboard(),
      ),
      UserRole.atencionCliente => const _RoleScaffold(
        title: 'Atención al cliente',
        child: SupportDashboard(),
      ),
      UserRole.administrador => const AdministrativeHome(),
      UserRole.trabajadorTienda => const _RoleScaffold(
        title: 'Trabajador de tienda',
        child: StoreOperationsScreen(),
      ),
    };
  }
}

class AdministrativeHome extends StatelessWidget {
  const AdministrativeHome({super.key});

  @override
  Widget build(BuildContext context) => const _RoleScaffold(
    title: 'Panel administrativo',
    child: OperationsAdminDashboard(),
  );
}

class _WarehouseHome extends StatelessWidget {
  const _WarehouseHome();

  @override
  Widget build(BuildContext context) => const DefaultTabController(
    length: 2,
    child: Column(
      children: [
        TabBar(
          indicatorColor: AppColors.green,
          labelColor: AppColors.green,
          unselectedLabelColor: AppColors.muted,
          tabs: [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Inventario'),
            Tab(icon: Icon(Icons.inventory_outlined), text: 'Preparación'),
          ],
        ),
        Expanded(
          child: TabBarView(children: [InventoryScreen(), FulfillmentScreen()]),
        ),
      ],
    ),
  );
}

class _RoleScaffold extends StatelessWidget {
  const _RoleScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showRole = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: softBackground,
        scrolledUnderElevation: 0,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          const AppGuideButton(),
          if (showRole)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  ShopScope.of(context).user.role.label,
                  style: const TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ShopScope.of(context).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.muted),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
