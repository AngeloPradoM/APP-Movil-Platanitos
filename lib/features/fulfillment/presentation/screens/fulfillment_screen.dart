import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../operations/data/remote_operations_repository.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';

class FulfillmentScreen extends StatefulWidget {
  const FulfillmentScreen({super.key});

  @override
  State<FulfillmentScreen> createState() => _FulfillmentScreenState();
}

class _FulfillmentScreenState extends State<FulfillmentScreen> {
  Future<List<FulfillmentTask>>? tasks;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && tasks != null) return;
    _revision = revision;
    tasks = _load();
  }

  Future<List<FulfillmentTask>> _load() =>
      ShopScope.of(context).operationsRepository?.fulfillmentTasks() ??
      Future.value(const []);

  Future<void> _run(FulfillmentTask task) async {
    final state = ShopScope.of(context);
    final repository = state.operationsRepository!;
    final worker = state.user.id ?? 'demo-almacen';
    try {
      switch (task.status) {
        case 'PENDING':
          await repository.startPreparation(task.orderId, worker);
        case 'PREPARING':
          await repository.markPrepared(task.orderId, worker);
        case 'PREPARED':
          await repository.dispatchOrder(
            task.orderId,
            worker,
            'demo-repartidor',
          );
        case 'DISPATCHED':
          final remote = repository;
          if (remote is! RemoteOperationsRepository) break;
          await remote.markInTransit(task.orderId);
        case 'IN_TRANSIT':
          final remote = repository;
          if (remote is! RemoteOperationsRepository) break;
          await remote.markDelivered(task.orderId);
      }
      if (mounted) {
        setState(() {
          tasks = _load();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error is StateError ? error.message : '$error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FulfillmentTask>>(
    future: tasks,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() {
            tasks = _load();
          }),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final values = snapshot.data!;
      final remoteOps =
          ShopScope.of(context).operationsRepository
              is RemoteOperationsRepository;
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() {
            tasks = next;
          });
          await next;
        },
        child: ListView(
          padding: operationsListPadding(context),
          children: [
            const OperationsPanelHeader(
              title: 'Preparación y despacho',
              subtitle:
                  'Prepara y despacha. Desde el despacho, el pedido pasa al repartidor.',
            ),
            const SizedBox(height: 16),
            if (values.isEmpty)
              const OperationsEmptyTile(
                message: 'No hay pedidos pendientes.',
              ),
            for (final task in values)
              OperationsTile(
                child: Semantics(
                  button: _action(task.status, remote: remoteOps) != null,
                  label:
                      'Pedido ${task.publicNumber}, ${_label(task.status)}, ${task.units} unidades',
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const OperationsAvatar(
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.publicNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${task.units} unidades · ${_label(task.status)}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              if (remoteOps &&
                                  (task.status == 'DISPATCHED' ||
                                      task.status == 'IN_TRANSIT'))
                                const Text(
                                  'Lo continúa el repartidor',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_action(task.status, remote: remoteOps) == null)
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.green,
                          ),
                      ],
                    ),
                    if (_action(task.status, remote: remoteOps) != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => _run(task),
                          child: Text(_action(task.status, remote: remoteOps)!),
                        ),
                      ),
                    ],
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

String _label(String value) => switch (value) {
  'PENDING' => 'Pendiente',
  'PREPARING' => 'En preparación',
  'PREPARED' => 'Listo para despacho',
  'DISPATCHED' => 'Despachado',
  'IN_TRANSIT' => 'En camino',
  _ => value,
};

String? _action(String value, {required bool remote}) => switch (value) {
  'PENDING' => 'Iniciar',
  'PREPARING' => 'Marcar listo',
  'PREPARED' => 'Despachar',
  'DISPATCHED' when !remote => 'Poner en camino',
  'IN_TRANSIT' when !remote => 'Marcar entregado',
  _ => null,
};
