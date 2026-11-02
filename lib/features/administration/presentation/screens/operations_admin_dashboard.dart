import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../inventory/data/remote_inventory_repository.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';

class OperationsAdminDashboard extends StatefulWidget {
  const OperationsAdminDashboard({
    super.key,
    this.onOpenInventory,
    this.onOpenFulfillment,
  });

  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenFulfillment;

  @override
  State<OperationsAdminDashboard> createState() =>
      _OperationsAdminDashboardState();
}

class _OperationsAdminDashboardState extends State<OperationsAdminDashboard> {
  Future<OperationsReport>? report;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && report != null) return;
    _revision = revision;
    report = _load();
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
      final openFulfillment = widget.onOpenFulfillment;
      final openInventory = widget.onOpenInventory;
      final metrics = <(String, String, IconData, VoidCallback?)>[
        ('Pedidos', '${value.orders}', Icons.receipt_long_outlined, openFulfillment),
        (
          'Pendientes',
          '${value.pendingOrders}',
          Icons.pending_actions_outlined,
          openFulfillment,
        ),
        (
          'Entregados',
          '${value.deliveredOrders}',
          Icons.task_alt_outlined,
          openFulfillment,
        ),
        (
          'Stock bajo',
          '${value.lowStockVariants}',
          Icons.warning_amber_outlined,
          openInventory,
        ),
        (
          'Entregas activas',
          '${value.activeDeliveries}',
          Icons.local_shipping_outlined,
          openFulfillment,
        ),
        (
          'Ventas',
          'S/ ${(value.totalSalesCents / 100).toStringAsFixed(2)}',
          Icons.payments_outlined,
          null,
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
                  'Los pedidos y el despacho se actualizan solos. Toca una tarjeta para abrirla.',
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
                    onTap: metric.$4,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const _CategoryPanel(),
            const SizedBox(height: 16),
            OperationsTile(
              onTap: openInventory ??
                  () => Navigator.push(
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

class _CategoryPanel extends StatefulWidget {
  const _CategoryPanel();

  @override
  State<_CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<_CategoryPanel> {
  Future<List<InventoryCategory>>? categories;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && categories != null) return;
    _revision = revision;
    categories = _load();
  }

  Future<List<InventoryCategory>> _load() async {
    final repository = ShopScope.of(context).inventoryRepository;
    if (repository is! RemoteInventoryRepository) return const [];
    return repository.categories();
  }

  Future<void> _toggle(InventoryCategory category, bool active) async {
    final repository = ShopScope.of(context).inventoryRepository;
    if (repository is! RemoteInventoryRepository) return;
    final previous = categories;
    final current = await categories;
    if (!mounted || current == null) return;
    setState(() {
      categories = Future.value([
        for (final item in current)
          if (item.id == category.id)
            InventoryCategory(
              id: item.id,
              name: item.name,
              slug: item.slug,
              productCount: item.productCount,
              isActive: active,
            )
          else
            item,
      ]);
    });
    try {
      await repository.setCategoryActive(category.id, active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Se habilitó una categoría del catálogo.'
                : 'Se deshabilitó una categoría del catálogo.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        categories = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la categoría.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<InventoryCategory>>(
    future: categories,
    builder: (context, snapshot) {
      final values = snapshot.data ?? const <InventoryCategory>[];
      if (values.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OperationsPanelHeader(
            title: 'Categorías',
            subtitle: 'Activa o pausa una categoría del catálogo.',
          ),
          const SizedBox(height: 8),
          for (final category in values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category.name),
              subtitle: Text('${category.productCount} productos'),
              value: category.isActive,
              onChanged: (value) => _toggle(category, value),
            ),
        ],
      );
    },
  );
}
