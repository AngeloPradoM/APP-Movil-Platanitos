import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../operations/data/remote_operations_repository.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';
import 'delivery_evidence_dialog.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({
    super.key,
    this.title = 'Historial de envíos',
    this.subtitle =
        'Pedidos ya entregados. Abre la constancia para ver nombre, firma y foto.',
  });

  final String title;
  final String subtitle;

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  Future<List<DeliveryTask>>? history;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && history != null) return;
    _revision = revision;
    history = _load();
  }

  Future<List<DeliveryTask>> _load() async {
    final repository = ShopScope.of(context).operationsRepository;
    if (repository is! RemoteOperationsRepository) return const [];
    return repository.deliveryHistory();
  }

  Future<void> _showEvidence(DeliveryTask item) async {
    final repository = ShopScope.of(context).operationsRepository;
    if (repository == null) return;
    final evidence = await repository.deliveryEvidence(item.id);
    if (!mounted) return;
    if (evidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta entrega no tiene constancia guardada.')),
      );
      return;
    }
    await showDeliveryEvidenceDetails(context, evidence);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<DeliveryTask>>(
    future: history,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() => history = _load()),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final values = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() => history = next);
          await next;
        },
        child: ListView(
          padding: operationsListPadding(context),
          children: [
            OperationsPanelHeader(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            const SizedBox(height: 16),
            if (values.isEmpty)
              const OperationsEmptyTile(
                message: 'Todavía no hay envíos entregados en el historial.',
              ),
            for (final item in values)
              OperationsTile(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OperationsAvatar(
                          icon: Icons.task_alt_outlined,
                          warning: !item.hasEvidence,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.publicNumber,
                                style: const TextStyle(fontWeight: FontWeight.w700),
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
                                item.recipientName == null ||
                                        item.recipientName!.isEmpty
                                    ? 'Entregado · ${_shortDate(item.assignedAt)}'
                                    : 'Recibió ${item.recipientName} · ${_shortDate(item.assignedAt)}',
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: item.hasEvidence
                            ? () => _showEvidence(item)
                            : null,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: Text(
                          item.hasEvidence
                              ? 'Ver evidencia'
                              : 'Sin evidencia',
                        ),
                      ),
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

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
