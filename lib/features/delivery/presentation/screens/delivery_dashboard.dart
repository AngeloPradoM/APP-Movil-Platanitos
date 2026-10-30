import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';
import 'delivery_evidence_dialog.dart';
import 'delivery_history_screen.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});

  @override
  Widget build(BuildContext context) => const DefaultTabController(
    length: 2,
    child: Column(
      children: [
        ShopTabBar(
          tabs: [
            Tab(icon: Icon(Icons.local_shipping_outlined), text: 'Activas'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _ActiveDeliveriesPanel(),
              DeliveryHistoryScreen(
                title: 'Mis envíos entregados',
                subtitle:
                    'Tu historial de repartos. Puedes abrir la evidencia de cada entrega.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActiveDeliveriesPanel extends StatefulWidget {
  const _ActiveDeliveriesPanel();

  @override
  State<_ActiveDeliveriesPanel> createState() => _ActiveDeliveriesPanelState();
}

class _ActiveDeliveriesPanelState extends State<_ActiveDeliveriesPanel> {
  Future<List<DeliveryTask>>? deliveries;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && deliveries != null) return;
    _revision = revision;
    deliveries = _load();
  }

  Future<List<DeliveryTask>> _load() {
    final state = ShopScope.of(context);
    return state.operationsRepository?.deliveries(
          state.user.id ?? 'demo-repartidor',
        ) ??
        Future.value(const []);
  }

  Future<void> _advance(DeliveryTask item) async {
    final next = switch (item.status) {
      'ASSIGNED' => 'PICKED_UP',
      'PICKED_UP' => 'IN_TRANSIT',
      _ => null,
    };
    if (next == null) return;
    try {
      await ShopScope.of(context).operationsRepository!
          .updateDelivery(item.id, next);
      if (mounted) setState(() => deliveries = _load());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la entrega.')),
        );
      }
    }
  }

  Future<void> _confirmDelivery(DeliveryTask item) async {
    final evidence = await showDeliveryEvidenceForm(context);
    if (evidence == null || !mounted) return;
    try {
      await ShopScope.of(context).operationsRepository!.confirmDelivery(
        deliveryId: item.id,
        recipientName: evidence.recipientName,
        signatureData: evidence.signatureData,
        photoBytes: evidence.photoBytes,
      );
      if (mounted) {
        setState(() => deliveries = _load());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega confirmada con evidencia digital.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo confirmar la entrega.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DeliveryTask>>(
    future: deliveries,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() => deliveries = _load()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() => deliveries = next);
          await next;
        },
        child: ListView(
          padding: operationsListPadding(context),
          children: [
            const OperationsPanelHeader(
              title: 'Entregas asignadas',
              subtitle:
                  'Los pedidos aparecen aquí cuando almacén los despacha. Primero recógelos y después confirma la entrega.',
            ),
            const SizedBox(height: 16),
            if (snapshot.data!.isEmpty)
              const OperationsEmptyTile(
                message: 'No hay entregas asignadas.',
              ),
            for (final item in snapshot.data!)
              OperationsTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const OperationsAvatar(
                          icon: Icons.local_shipping_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.publicNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.address,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Estado: ${_deliveryLabel(item.status)}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ({'ASSIGNED', 'PICKED_UP'}.contains(item.status))
                          FilledButton(
                            onPressed: () => _advance(item),
                            child: Text(_deliveryAction(item.status)),
                          ),
                        if (item.status == 'IN_TRANSIT')
                          FilledButton.icon(
                            onPressed: () => _confirmDelivery(item),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Confirmar con evidencia'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

String _deliveryLabel(String value) => switch (value) {
  'ASSIGNED' => 'Asignado',
  'PICKED_UP' => 'Recogido',
  'IN_TRANSIT' => 'En camino',
  'DELIVERED' => 'Entregado',
  'FAILED' => 'Entrega fallida',
  _ => value,
};

String _deliveryAction(String value) => switch (value) {
  'ASSIGNED' => 'Confirmar recojo',
  'PICKED_UP' => 'Iniciar ruta',
  _ => 'Completado',
};
