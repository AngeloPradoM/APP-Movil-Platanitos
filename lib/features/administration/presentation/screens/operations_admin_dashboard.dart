import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';

class OperationsAdminDashboard extends StatefulWidget {
  const OperationsAdminDashboard({super.key});

  @override
  State<OperationsAdminDashboard> createState() =>
      _OperationsAdminDashboardState();
}

class _OperationsAdminDashboardState extends State<OperationsAdminDashboard> {
  Future<OperationsReport>? report;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    report ??= _load();
  }

  Future<OperationsReport> _load() async =>
      await ShopScope.of(context).operationsRepository?.report() ??
      const OperationsReport(
        orders: 0,
        pendingOrders: 0,
        deliveredOrders: 0,
        lowStockVariants: 0,
        openSupportRequests: 0,
        activeDeliveries: 0,
        totalSalesCents: 0,
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<OperationsReport>(
    future: report,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() {
            report = _load();
          }),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final value = snapshot.data!;
      final metrics = <(String, String, IconData)>[
        ('Pedidos', '${value.orders}', Icons.receipt_long_outlined),
        (
          'Pendientes',
          '${value.pendingOrders}',
          Icons.pending_actions_outlined,
        ),
        ('Entregados', '${value.deliveredOrders}', Icons.task_alt_outlined),
        (
          'Stock bajo',
          '${value.lowStockVariants}',
          Icons.warning_amber_outlined,
        ),
        (
          'Casos abiertos',
          '${value.openSupportRequests}',
          Icons.support_agent_outlined,
        ),
        (
          'Entregas activas',
          '${value.activeDeliveries}',
          Icons.local_shipping_outlined,
        ),
        (
          'Ventas simuladas',
          'S/ ${(value.totalSalesCents / 100).toStringAsFixed(2)}',
          Icons.payments_outlined,
        ),
      ];
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() {
            report = next;
          });
          await next;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Resumen operativo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Indicadores calculados con los datos locales de la demostración.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: 190,
                    child: Card(
                      child: ListTile(
                        leading: Icon(metric.$3),
                        title: Text(metric.$2),
                        subtitle: Text(metric.$1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Revisar inventario'),
                subtitle: const Text('Stock físico, reservado y disponible'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Inventario')),
                      body: const InventoryScreen(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
