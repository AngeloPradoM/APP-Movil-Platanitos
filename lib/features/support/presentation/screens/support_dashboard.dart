import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../operations/domain/operations_models.dart';
import '../../../operations/presentation/widgets/operations_error_view.dart';
import '../../../operations/presentation/widgets/operations_panel.dart';

class SupportDashboard extends StatefulWidget {
  const SupportDashboard({super.key});

  @override
  State<SupportDashboard> createState() => _SupportDashboardState();
}

class _SupportDashboardState extends State<SupportDashboard>
    with SingleTickerProviderStateMixin {
  Future<List<SupportRequestRecord>>? requests;
  int _revision = -1;
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = ShopScope.of(context).liveRevision;
    if (_revision == revision && requests != null) return;
    _revision = revision;
    requests = _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<List<SupportRequestRecord>> _load() =>
      ShopScope.of(context).operationsRepository?.supportRequests() ??
      Future.value(const []);

  Future<void> _setStatus(
    SupportRequestRecord request,
    String status, {
    String? note,
  }) async {
    try {
      await ShopScope.of(context).operationsRepository!.updateSupportRequest(
        request.id,
        status,
        note: note,
      );
      if (mounted) {
        setState(() {
          requests = _load();
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la solicitud.')),
        );
      }
    }
  }

  Future<void> _askNoteAndSet(
    SupportRequestRecord request,
    String status,
    String title,
  ) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: note,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(
            labelText: status == 'REJECTED'
                ? 'Motivo del rechazo'
                : 'Respuesta al cliente',
            hintText: status == 'REJECTED'
                ? 'Ej.: fuera de plazo de 7 días…'
                : 'Ej.: se coordinó el recojo / se aprueba el cambio…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'REJECTED' ? 'Rechazar' : 'Resolver'),
          ),
        ],
      ),
    );
    final text = note.text.trim();
    note.dispose();
    if (confirmed != true || !mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nota es obligatoria.')),
      );
      return;
    }
    await _setStatus(request, status, note: text);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SupportRequestRecord>>(
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
      final all = snapshot.data!;
      final pending = [
        for (final item in all)
          if (item.status == 'REGISTERED') item,
      ];
      final review = [
        for (final item in all)
          if (item.status == 'IN_REVIEW') item,
      ];
      final closed = [
        for (final item in all)
          if (item.status == 'RESOLVED' || item.status == 'REJECTED') item,
      ];

      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OperationsPanelHeader(
              title: 'Bandeja de posventa',
              subtitle:
                  'Atiende, resuelve o rechaza cambios, devoluciones y reclamos.',
            ),
          ),
          ShopTabBar(
            controller: _tabs,
            tabs: [
              Tab(text: 'Pendientes (${pending.length})'),
              Tab(text: 'En revisión (${review.length})'),
              Tab(text: 'Cerradas (${closed.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SupportList(
                  items: pending,
                  empty: 'No hay solicitudes nuevas.',
                  onRefresh: () async {
                    final next = _load();
                    setState(() => requests = next);
                    await next;
                  },
                  trailing: (request) => Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            _askNoteAndSet(request, 'REJECTED', 'Rechazar solicitud'),
                        child: const Text('Rechazar'),
                      ),
                      FilledButton(
                        onPressed: () => _setStatus(request, 'IN_REVIEW'),
                        child: const Text('Atender'),
                      ),
                    ],
                  ),
                ),
                _SupportList(
                  items: review,
                  empty: 'No hay casos en revisión.',
                  onRefresh: () async {
                    final next = _load();
                    setState(() => requests = next);
                    await next;
                  },
                  trailing: (request) => Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            _askNoteAndSet(request, 'REJECTED', 'Rechazar solicitud'),
                        child: const Text('Rechazar'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            _askNoteAndSet(request, 'RESOLVED', 'Resolver solicitud'),
                        child: const Text('Resolver'),
                      ),
                    ],
                  ),
                ),
                _SupportList(
                  items: closed,
                  empty: 'Todavía no hay solicitudes cerradas.',
                  onRefresh: () async {
                    final next = _load();
                    setState(() => requests = next);
                    await next;
                  },
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _SupportList extends StatelessWidget {
  const _SupportList({
    required this.items,
    required this.empty,
    required this.onRefresh,
    this.trailing,
  });

  final List<SupportRequestRecord> items;
  final String empty;
  final Future<void> Function() onRefresh;
  final Widget Function(SupportRequestRecord request)? trailing;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      padding: operationsListPadding(context),
      children: [
        if (items.isEmpty) OperationsEmptyTile(message: empty),
        for (final request in items)
          OperationsTile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OperationsAvatar(
                      icon: _typeIcon(request.type),
                      warning:
                          request.status != 'RESOLVED' &&
                          request.status != 'REJECTED',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${request.publicNumber} · ${_typeLabel(request.type)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.customerName == null ||
                                    request.customerName!.isEmpty
                                ? 'Cliente'
                                : '${request.customerName}'
                                    '${request.customerEmail == null || request.customerEmail!.isEmpty ? '' : ' · ${request.customerEmail}'}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.reason,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(request.status),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (request.resolutionNote != null &&
                              request.resolutionNote!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Nota: ${request.resolutionNote}',
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (request.status == 'RESOLVED')
                      const Icon(Icons.check_circle, color: AppColors.green),
                    if (request.status == 'REJECTED')
                      const Icon(Icons.cancel_outlined, color: AppColors.danger),
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailing!(request),
                  ),
                ],
              ],
            ),
          ),
      ],
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
  'REGISTERED' => 'Registrado',
  'IN_REVIEW' => 'En revisión',
  'RESOLVED' => 'Resuelto',
  'REJECTED' => 'Rechazado',
  _ => value,
};
