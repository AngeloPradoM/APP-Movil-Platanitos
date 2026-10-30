import 'package:flutter/material.dart';

import '../../../../app/navigation/navigation.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../operations/domain/operations_models.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String type = 'CHANGE';
  String? orderId;
  final reason = TextEditingController();
  Future<List<SupportRequestRecord>>? requests;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ShopScope.of(context);
    orderId ??= state.orders.isEmpty ? null : state.orders.first.id;
    requests ??= _load();
  }

  Future<List<SupportRequestRecord>> _load() {
    final state = ShopScope.of(context);
    return state.operationsRepository?.supportRequests(userId: state.user.id) ??
        Future.value(const []);
  }

  Future<void> _submit() async {
    final state = ShopScope.of(context);
    if (orderId == null ||
        reason.text.trim().isEmpty ||
        state.user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un pedido y describe tu solicitud.'),
        ),
      );
      return;
    }
    try {
      final records = await state.operationsRepository!.orders(
        userId: state.user.id,
      );
      final order = records.firstWhere((item) => item.publicNumber == orderId);
      await state.operationsRepository!.createSupportRequest(
        orderId: order.id,
        userId: state.user.id!,
        type: type,
        reason: reason.text,
      );
      reason.clear();
      if (mounted) {
        setState(() {
          requests = _load();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud registrada localmente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar la solicitud.')),
        );
      }
    }
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    if (state.operationsRepository == null) return const _InformativeSupport();
    return PageFrame(
      title: 'Centro de ayuda',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Nueva solicitud',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: orderId,
            decoration: const InputDecoration(labelText: 'Pedido'),
            items: [
              for (final order in state.orders)
                DropdownMenuItem(value: order.id, child: Text(order.id)),
            ],
            onChanged: (value) => setState(() => orderId = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in const <(String, String)>[
                ('CHANGE', 'Cambio'),
                ('RETURN', 'Devolución'),
                ('CLAIM', 'Reclamo'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: type == option.$1,
                  onSelected: (_) => setState(() => type = option.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Motivo y detalle'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.orders.isEmpty ? null : _submit,
            child: const Text('Registrar solicitud'),
          ),
          const SizedBox(height: 24),
          Text(
            'Mis solicitudes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          FutureBuilder<List<SupportRequestRecord>>(
            future: requests,
            builder: (context, snapshot) {
              final values = snapshot.data ?? const <SupportRequestRecord>[];
              if (snapshot.hasError) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.sync_problem_outlined),
                    title: const Text('No se pudieron cargar las solicitudes.'),
                    trailing: IconButton(
                      tooltip: 'Reintentar',
                      onPressed: () => setState(() {
                        requests = _load();
                      }),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (values.isEmpty) {
                return const Card(
                  child: ListTile(
                    title: Text('Todavía no tienes solicitudes.'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final item in values)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.support_agent_outlined),
                        title: Text('${item.publicNumber} · ${item.type}'),
                        subtitle: Text(
                          '${item.reason}\nEstado: ${item.status}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InformativeSupport extends StatelessWidget {
  const _InformativeSupport();
  @override
  Widget build(BuildContext context) => const PageFrame(
    title: 'Centro de ayuda',
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Selecciona un pedido para registrar cambios, devoluciones o reclamos.',
        ),
      ),
    ),
  );
}

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});
  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool retrying = false;
  Future<void> retry() async {
    setState(() => retrying = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) goHome(context);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Conexión',
    child: retrying
        ? const Center(child: CircularProgressIndicator())
        : EmptyState(
            icon: Icons.wifi_off_outlined,
            title: 'Sin conexión',
            message: 'Revisa tu conexión a internet e inténtalo nuevamente.',
            action: 'Reintentar',
            onAction: retry,
          ),
  );
}
