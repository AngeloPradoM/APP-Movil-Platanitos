import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import 'delivery_evidence_dialog.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  Future<List<DeliveryTask>>? deliveries;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deliveries ??= _load();
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
      if (mounted) {
        setState(() {
          deliveries = _load();
        });
      }
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
        setState(() {
          deliveries = _load();
        });
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

  Future<void> _showEvidence(DeliveryTask item) async {
    final evidence = await ShopScope.of(context).operationsRepository!
        .deliveryEvidence(item.id);
    if (evidence != null && mounted) {
      await showDeliveryEvidenceDetails(context, evidence);
    }
  }

  Future<void> _incident(DeliveryTask item) async {
    final controller = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar incidencia'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (accepted == true && controller.text.trim().isNotEmpty && mounted) {
      await ShopScope.of(context).operationsRepository!
          .reportIncident(item.id, 'DELIVERY', controller.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incidencia registrada.')));
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DeliveryTask>>(
    future: deliveries,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() {
            deliveries = _load();
          }),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() {
            deliveries = next;
          });
          await next;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Entregas asignadas',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (snapshot.data!.isEmpty)
              const Card(
                child: ListTile(title: Text('No hay entregas asignadas.')),
              ),
            for (final item in snapshot.data!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: Text(item.publicNumber),
                        subtitle: Text(
                          '${item.address}\nEstado: ${_deliveryLabel(item.status)}',
                        ),
                        isThreeLine: true,
                      ),
                      Wrap(
                        spacing: 8,
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
                          if (item.status == 'IN_TRANSIT')
                            OutlinedButton(
                              onPressed: () => _incident(item),
                              child: const Text('Incidencia'),
                            ),
                          if (item.status == 'DELIVERED' && item.hasEvidence)
                            OutlinedButton.icon(
                              onPressed: () => _showEvidence(item),
                              icon: const Icon(Icons.receipt_long_outlined),
                              label: const Text('Ver constancia'),
                            ),
                        ],
                      ),
                    ],
                  ),
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
