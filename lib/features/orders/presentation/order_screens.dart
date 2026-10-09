import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/navigation.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../support/presentation/support_screens.dart';
import '../../catalog/presentation/catalog_screens.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool history = false;
  @override
  Widget build(BuildContext context) {
    final orders = ShopScope.of(context).orders
        .where((order) => (order.status == OrderStatus.delivered) == history)
        .toList();
    return PageFrame(
      title: 'Mis pedidos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('En curso')),
                ButtonSegment(value: true, label: Text('Historial')),
              ],
              selected: {history},
              onSelectionChanged: (value) =>
                  setState(() => history = value.first),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: history
                        ? 'No hay pedidos en tu historial'
                        : 'Aún no tienes pedidos',
                    message: 'Cuando compres, podrás seguirlos aquí.',
                    action: 'Ir a comprar',
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const PageFrame(
                          title: 'Calzado',
                          child: CatalogScreen(),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: orders.length,
                    itemBuilder: (_, index) {
                      final order = orders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 12,
                              children: [
                                Text(
                                  '#${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Chip(
                                  label: Text(order.status.label),
                                  backgroundColor: AppColors.softGreen,
                                ),
                              ],
                            ),
                            const Divider(),
                            ...order.items.map(
                              (item) => OrderProductRow(item: item),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${order.items.fold<int>(0, (sum, item) => sum + item.quantity)} productos · ${money(order.total)}',
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      order.status == OrderStatus.delivered
                                      ? DeliveredScreen(order: order)
                                      : TrackingScreen(order: order),
                                ),
                              ),
                              child: const Text('Ver detalle del pedido'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class OrderProductRow extends StatelessWidget {
  const OrderProductRow({super.key, required this.item});
  final OrderItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          height: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ShopImage(item.product.image),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                'Talla ${item.size} ${item.system.name.toUpperCase()} · Cantidad ${item.quantity}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 5),
              Text(
                money(item.subtotal),
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class OrderReceipt extends StatelessWidget {
  const OrderReceipt({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        receiptRow('ID Pedido', '#${order.id}'),
        const Divider(height: 28),
        receiptRow('Entrega estimada', order.estimate),
        const Divider(height: 28),
        receiptRow('Método de pago', order.payment.label),
        const Divider(height: 28),
        receiptRow('Total', money(order.total)),
      ],
    ),
  );
  Widget receiptRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return PageFrame(
      title: 'Seguir mi pedido',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PEDIDO #${order.id}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  order.status == OrderStatus.preparation
                      ? 'En preparación'
                      : order.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Entrega estimada: ${order.estimate}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          OrderTimeline(order: order),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DeliveryScreen(order: order),
              ),
            ),
            child: const Text('Ver detalle de entrega'),
          ),
          const SizedBox(height: 12),
          if (order.status != OrderStatus.delivered)
            OutlinedButton(
              onPressed: () {
                state.advanceOrder(order);
                feedback(context, 'Estado simulado: ${order.status.label}');
              },
              child: const Text('Simular siguiente estado'),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DeliveredScreen(order: order),
                ),
              ),
              child: const Text('Ver pedido entregado'),
            ),
          const SizedBox(height: 12),
          const Text(
            'Seguimiento de demostración, sin conexión logística real.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          TextButton(
            onPressed: () => goHome(context),
            child: const Text('Volver al Inicio'),
          ),
        ],
      ),
    );
  }
}

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return PageFrame(
      title: 'Detalle de entrega',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OrderReceipt(order: order),
          const SizedBox(height: 20),
          Text(
            'Estado: ${order.status.label}',
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Información de entrega',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Dirección'),
            subtitle: Text(
              order.address == null
                  ? 'Pendiente de confirmar'
                  : '${order.address!.line1}\n${order.address!.region}'
                        '${order.address!.reference.isEmpty ? '' : '\nRef.: ${order.address!.reference}'}',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.local_shipping_outlined),
            title: Text('Transportista'),
            subtitle: Text('Pendiente de asignación'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.inventory_2_outlined),
            title: Text('Código de seguimiento'),
            subtitle: Text('Aún no disponible'),
          ),
          const Divider(),
          const Text(
            'Resumen del pedido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          ...order.items.map((item) => OrderProductRow(item: item)),
          SummaryCard(subtotal: order.subtotal, shipping: order.shipping),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              state.deliverOrder(order);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DeliveredScreen(order: order),
                ),
              );
            },
            child: Text(
              order.status == OrderStatus.delivered
                  ? 'Ver pedido entregado'
                  : 'Simular pedido entregado',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al seguimiento'),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
            ),
            child: const Text('Necesito ayuda'),
          ),
        ],
      ),
    );
  }
}

class DeliveredScreen extends StatelessWidget {
  const DeliveredScreen({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Pedido entregado',
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.green,
          child: Icon(Icons.check, color: Colors.white, size: 42),
        ),
        const SizedBox(height: 24),
        const Text(
          'PEDIDO COMPLETADO',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.green,
            fontSize: 12,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '¡Pedido entregado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu compra ha llegado a su destino. ¡Gracias por elegirnos!',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        OrderReceipt(order: order),
        const SizedBox(height: 20),
        const ListTile(
          tileColor: AppColors.softGreen,
          leading: Icon(Icons.help_outline, color: AppColors.green),
          title: Text('¿Necesitas ayuda con tu pedido?'),
          subtitle: Text('Nuestro equipo está listo para ayudarte.'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => goHome(context),
          child: const Text('Volver al Inicio'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
          ),
          child: const Text('Necesito ayuda'),
        ),
      ],
    ),
  );
}
