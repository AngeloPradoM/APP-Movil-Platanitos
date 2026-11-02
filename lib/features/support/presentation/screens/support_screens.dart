import 'package:flutter/material.dart';

import '../../../../app/navigation/navigation.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../orders/domain/order_models.dart';

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
  bool submitting = false;
  int _revision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ShopScope.of(context);
    final revision = state.liveRevision;
    orderId ??= state.orders.isEmpty ? null : _eligibleOrders(state.orders).firstOrNull?.id;
    if (_revision != revision || requests == null) {
      _revision = revision;
      requests = _load();
    }
  }

  List<ShopOrder> _eligibleOrders(List<ShopOrder> orders) {
    return [
      for (final order in orders)
        if (_allowsType(order, type)) order,
    ];
  }

  bool _allowsType(ShopOrder order, String selected) {
    if (selected == 'CLAIM') {
      return order.status == OrderStatus.preparation ||
          order.status == OrderStatus.dispatch ||
          order.status == OrderStatus.transit ||
          order.status == OrderStatus.delivered;
    }
    return order.status == OrderStatus.delivered;
  }

  Future<List<SupportRequestRecord>> _load() {
    final state = ShopScope.of(context);
    return state.operationsRepository?.supportRequests(userId: state.user.id) ??
        Future.value(const []);
  }

  Future<void> _submit() async {
    final state = ShopScope.of(context);
    final repository = state.operationsRepository;
    if (repository == null ||
        orderId == null ||
        reason.text.trim().length < 10 ||
        submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Elige un pedido entregado (o en curso si es reclamo) y escribe al menos 10 caracteres.',
          ),
        ),
      );
      return;
    }
    setState(() => submitting = true);
    try {
      await repository.createSupportRequest(
        orderId: orderId!,
        userId: state.user.id ?? '',
        type: type,
        reason: reason.text.trim(),
      );
      reason.clear();
      if (!mounted) return;
      setState(() {
        requests = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada. Atención al cliente la revisará pronto.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message
                  : 'No se pudo registrar la solicitud.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
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
    final eligible = _eligibleOrders(state.orders);
    if (orderId != null && !eligible.any((order) => order.id == orderId)) {
      orderId = eligible.firstOrNull?.id;
    }
    return PageFrame(
      title: 'Centro de ayuda',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Nueva solicitud',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Cambio y devolución: solo pedidos entregados. '
            'Reclamo: también pedidos en preparación, despacho o en camino.',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
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
                  onSelected: (_) => setState(() {
                    type = option.$1;
                    final next = _eligibleOrders(state.orders);
                    if (!next.any((order) => order.id == orderId)) {
                      orderId = next.firstOrNull?.id;
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('support-order-$type-$orderId-${eligible.length}'),
            initialValue:
                eligible.any((order) => order.id == orderId) ? orderId : null,
            decoration: const InputDecoration(labelText: 'Pedido'),
            items: [
              for (final order in eligible)
                DropdownMenuItem(
                  value: order.id,
                  child: Text(
                    '${order.id} · ${_orderStatus(order.status)}',
                  ),
                ),
            ],
            onChanged: eligible.isEmpty
                ? null
                : (value) => setState(() => orderId = value),
          ),
          if (eligible.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              type == 'CLAIM'
                  ? 'No tienes pedidos aptos para reclamo.'
                  : 'Necesitas un pedido entregado para cambio o devolución.',
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: reason,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivo y detalle',
              hintText: 'Ej.: talla incorrecta, producto dañado, demora…',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: eligible.isEmpty || submitting ? null : _submit,
            child: Text(submitting ? 'Enviando…' : 'Registrar solicitud'),
          ),
          const SizedBox(height: 24),
          Text(
            'Mis solicitudes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
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
                        leading: Icon(
                          _typeIcon(item.type),
                          color: AppColors.darkGreen,
                        ),
                        title: Text(
                          '${item.publicNumber} · ${_typeLabel(item.type)}',
                        ),
                        subtitle: Text(
                          '${item.reason}'
                          '\nEstado: ${_statusLabel(item.status)}'
                          '${item.resolutionNote == null || item.resolutionNote!.isEmpty ? '' : '\nRespuesta: ${item.resolutionNote}'}',
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
          'Inicia sesión en modo remoto para registrar cambios, devoluciones o reclamos.',
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

IconData _typeIcon(String value) => switch (value) {
  'CHANGE' => Icons.swap_horiz,
  'RETURN' => Icons.assignment_return_outlined,
  'CLAIM' => Icons.report_problem_outlined,
  _ => Icons.support_agent_outlined,
};

String _typeLabel(String value) => switch (value) {
  'CHANGE' => 'Cambio',
  'RETURN' => 'Devolución',
  'CLAIM' => 'Reclamo',
  _ => value,
};

String _statusLabel(String value) => switch (value) {
  'REGISTERED' => 'Registrado · pendiente de atención',
  'IN_REVIEW' => 'En revisión por atención al cliente',
  'RESOLVED' => 'Resuelto',
  'REJECTED' => 'Rechazado',
  _ => value,
};

String _orderStatus(OrderStatus status) => status.label;
