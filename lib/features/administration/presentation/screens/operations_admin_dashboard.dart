import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';

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
          padding: operationsListPadding(context),
          children: [
            const OperationsPanelHeader(
              title: 'Resumen operativo',
              subtitle:
                  'Indicadores calculados con los datos locales de la demostración.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final metric in metrics)
                  OperationsMetricCard(
                    label: metric.$1,
                    value: metric.$2,
                    icon: metric.$3,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OperationsTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    backgroundColor: softBackground,
                    appBar: AppBar(
                      backgroundColor: softBackground,
                      title: const Text('Inventario'),
                    ),
                    body: const InventoryScreen(),
                  ),
                ),
              ),
              child: const Row(
                children: [
                  OperationsAvatar(icon: Icons.inventory_2_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revisar inventario',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Stock físico, reservado y disponible',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
