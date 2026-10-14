import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';

class FulfillmentScreen extends StatefulWidget {
  const FulfillmentScreen({super.key});

  @override
  State<FulfillmentScreen> createState() => _FulfillmentScreenState();
}

class _FulfillmentScreenState extends State<FulfillmentScreen> {
  Future<List<FulfillmentTask>>? tasks;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    tasks ??= _load();
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
      return RefreshIndicator(
        onRefresh: () async {
          final next = _load();
          setState(() {
            tasks = next;
          });
          await next;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Preparación y despacho',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'El despacho descuenta el stock reservado y asigna el pedido al repartidor.',
            ),
            const SizedBox(height: 16),
            if (values.isEmpty)
              const Card(
                child: ListTile(title: Text('No hay pedidos pendientes.')),
              ),
            for (final task in values)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(task.publicNumber),
                        subtitle: Text(
                          '${task.units} unidades · ${_label(task.status)}',
                        ),
                        trailing: _action(task.status) == null
                            ? const Icon(Icons.check_circle_outline)
                            : null,
                      ),
                      if (_action(task.status) != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => _run(task),
                            child: Text(_action(task.status)!),
                          ),
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

String _label(String value) => switch (value) {
  'PENDING' => 'Pendiente',
  'PREPARING' => 'En preparación',
  'PREPARED' => 'Listo para despacho',
  'DISPATCHED' => 'Despachado',
  _ => value,
};

String? _action(String value) => switch (value) {
  'PENDING' => 'Iniciar',
  'PREPARING' => 'Marcar listo',
  'PREPARED' => 'Despachar',
  _ => null,
};
