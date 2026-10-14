import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';

class SupportDashboard extends StatefulWidget {
  const SupportDashboard({super.key});

  @override
  State<SupportDashboard> createState() => _SupportDashboardState();
}

class _SupportDashboardState extends State<SupportDashboard> {
  Future<List<SupportRequestRecord>>? requests;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    requests ??= _load();
  }

  Future<List<SupportRequestRecord>> _load() =>
      ShopScope.of(context).operationsRepository?.supportRequests() ??
      Future.value(const []);

  Future<void> _advance(SupportRequestRecord request) async {
    final next = request.status == 'REGISTERED' ? 'IN_REVIEW' : 'RESOLVED';
    try {
      await ShopScope.of(context).operationsRepository!
          .updateSupportRequest(request.id, next);
      if (mounted) {
        setState(() {
          requests = _load();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la solicitud.')),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<SupportRequestRecord>>(
    future: requests,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return OperationsErrorView(
          onRetry: () => setState(() {
            requests = _load();
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
            requests = next;
          });
          await next;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Solicitudes posventa',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Cambios, devoluciones y reclamos registrados por clientes.',
            ),
            const SizedBox(height: 16),
            if (snapshot.data!.isEmpty)
              const Card(
                child: ListTile(title: Text('No hay solicitudes registradas.')),
              ),
            for (final request in snapshot.data!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.support_agent_outlined),
                        title: Text(
                          '${request.publicNumber} · ${_type(request.type)}',
                        ),
                        subtitle: Text(
                          '${request.reason}\n${_supportStatus(request.status)}',
                        ),
                        isThreeLine: true,
                        trailing: request.status == 'RESOLVED'
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      if (request.status != 'RESOLVED')
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () => _advance(request),
                            child: Text(
                              request.status == 'REGISTERED'
                                  ? 'Atender'
                                  : 'Resolver',
                            ),
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

String _type(String value) => switch (value) {
  'CHANGE' => 'Cambio',
  'RETURN' => 'Devolución',
  'CLAIM' => 'Reclamo',
  _ => value,
};

String _supportStatus(String value) => switch (value) {
  'REGISTERED' => 'Registrado',
  'IN_REVIEW' => 'En revisión',
  'RESOLVED' => 'Resuelto',
  _ => value,
};
