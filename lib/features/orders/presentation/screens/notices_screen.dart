import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/orders_repository.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  Future<List<OrderNotice>>? notices;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    notices ??= _load();
  }

  Future<List<OrderNotice>> _load() {
    final state = ShopScope.of(context);
    final token = state.accessToken;
    final repository = state.ordersRepository;
    if (token == null || repository == null) return Future.value(const []);
    return repository.notices(accessToken: token);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avisos')),
    body: FutureBuilder<List<OrderNotice>>(
      future: notices,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final values = snapshot.data!;
        if (values.isEmpty) {
          return const Center(
            child: Text(
              'Todavía no hay avisos de pago o envío.',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final next = _load();
            setState(() => notices = next);
            await next;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: values.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notice = values[index];
              return ListTile(
                tileColor: AppColors.softGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(notice.body),
                trailing: Text('${notice.createdAt.day}/${notice.createdAt.month}'),
              );
            },
          ),
        );
      },
    ),
  );
}
