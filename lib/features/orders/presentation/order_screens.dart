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

void _openSupport(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
);

List<Widget> _helpAction(BuildContext context) => [
  IconButton(
    tooltip: 'Ayuda',
    onPressed: () => _openSupport(context),
    icon: const Icon(Icons.help_outline),
  ),
];

(String, String, IconData) _statusInfo(OrderStatus status) => switch (status) {
  OrderStatus.preparation => (
    'En preparación',
    'Estamos preparando tu compra para el despacho.',
    Icons.inventory_2_outlined,
  ),
  OrderStatus.dispatch => (
    'Despachado',
    'Tu compra salió de nuestro almacén.',
    Icons.outbox_outlined,
  ),
  OrderStatus.transit => (
    'En camino',
    'Tu compra está en ruta hacia tu dirección.',
    Icons.local_shipping_outlined,
  ),
  OrderStatus.delivered => (
    'Entregado',
    'Tu compra llegó a su destino.',
    Icons.check_circle_outline,
  ),
};

/// Tarjeta blanca con borde suave usada en las pantallas del pedido.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: color == AppColors.softGreen
            ? AppColors.softGreen
            : AppColors.border,
      ),
    ),
    child: child,
  );
}

class OrderNumber extends StatelessWidget {
  const OrderNumber({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => Text(
    'Pedido #${order.id}',
    style: const TextStyle(
      color: AppColors.darkGreen,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class OrderFootnote extends StatelessWidget {
  const OrderFootnote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
    ),
  );
}

/// Círculo verde suave con un check, usado al confirmar compra o entrega.
class OrderCheckBadge extends StatelessWidget {
  const OrderCheckBadge({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: AppColors.softGreen,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        color: AppColors.darkGreen,
        size: 48,
      ),
    ),
  );
}

class OrderReceipt extends StatelessWidget {
  const OrderReceipt({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => OrderCard(
    color: softBackground,
    child: Column(
      children: [
        receiptRow('ID del Pedido', '#${order.id}', highlight: true),
        const SizedBox(height: 14),
        receiptRow('Entrega Estimada', order.estimate),
        const SizedBox(height: 14),
        receiptRow('Pago Realizado', order.payment.shortLabel),
        const SizedBox(height: 14),
        receiptRow('Total', money(order.total)),
      ],
    ),
  );
  static Widget receiptRow(
    String label,
    String value, {
    bool highlight = false,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.ink, fontSize: 13),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.darkGreen : AppColors.ink,
          ),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppColors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
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

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final (title, message, icon) = _statusInfo(order.status);
    return PageFrame(
      title: 'Seguir mi pedido',
      actions: _helpAction(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          OrderNumber(order: order),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.darkGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OrderCard(
            color: AppColors.softGreen,
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.darkGreen,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Entrega Estimada',
                        style: TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        order.estimate,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OrderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progreso de tu pedido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                OrderTimeline(order: order),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const OrderFootnote(
            'Estado ilustrativo. El seguimiento se actualizará cuando se confirme cada etapa.',
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: primaryButtonStyle,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DeliveryScreen(order: order),
              ),
            ),
            child: const Text('Ver detalle de entrega'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: outlineGreenButtonStyle,
            onPressed: () => goHome(context),
            child: const Text('Volver al Inicio'),
          ),
          const SizedBox(height: 4),
          if (order.status != OrderStatus.delivered)
            TextButton(
              onPressed: () {
                state.advanceOrder(order);
                feedback(context, 'Estado simulado: ${order.status.label}');
              },
              child: const Text('Simular siguiente estado'),
            )
          else
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => DeliveredScreen(order: order),
                ),
              ),
              child: const Text('Ver pedido entregado'),
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
    final (title, _, icon) = _statusInfo(order.status);
    final address = order.address;
    final units = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return PageFrame(
      title: 'Detalle de entrega',
      actions: _helpAction(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          OrderNumber(order: order),
          const SizedBox(height: 14),
          OrderCard(
            color: AppColors.softGreen,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.darkGreen, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OrderReceipt.receiptRow('Entrega Estimada', order.estimate),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OrderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información de entrega',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Dirección de entrega',
                  value: address == null
                      ? 'Pendiente de confirmar'
                      : '${address.line1}\n${address.region}'
                            '${address.reference.isEmpty ? '' : '\nRef.: ${address.reference}'}',
                ),
                const _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Transportista',
                  value: 'Pendiente de asignación',
                ),
                const _InfoRow(
                  icon: Icons.qr_code_scanner,
                  label: 'Código de seguimiento',
                  value: 'Aún no disponible',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OrderCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del pedido',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                OrderReceipt.receiptRow(
                  'ID del Pedido',
                  '#${order.id}',
                  highlight: true,
                ),
                const SizedBox(height: 12),
                OrderReceipt.receiptRow(
                  'Pago Realizado',
                  order.payment.shortLabel,
                ),
                const SizedBox(height: 12),
                OrderReceipt.receiptRow('Total', money(order.total)),
                const Divider(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$units ${units == 1 ? 'producto' : 'productos'}: '
                        '${order.items.map((item) => '${item.product.name} ×${item.quantity}').join(', ')}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const OrderFootnote(
            'Estado ilustrativo. Los datos logísticos se mostrarán al ser confirmados.',
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: primaryButtonStyle,
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver al seguimiento'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: outlineGreenButtonStyle,
            onPressed: () => _openSupport(context),
            child: const Text('Necesito ayuda'),
          ),
          const SizedBox(height: 4),
          TextButton(
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
    title: 'Mi pedido',
    actions: _helpAction(context),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        OrderNumber(order: order),
        const SizedBox(height: 22),
        const OrderCheckBadge(),
        const SizedBox(height: 18),
        const Text(
          '¡Pedido entregado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu compra ha llegado a su destino. ¡Gracias por elegirnos!',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        OrderReceipt(order: order),
        const SizedBox(height: 14),
        Material(
          color: softBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openSupport(context),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppColors.darkGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Necesitas ayuda con tu pedido?',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Si algo no llegó como esperabas, estamos para ayudarte.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const OrderFootnote(
          'Confirmación ilustrativa. La fecha de entrega y el receptor están pendientes de confirmar.',
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: primaryButtonStyle,
          onPressed: () => goHome(context),
          child: const Text('Volver al Inicio'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: outlineGreenButtonStyle,
          onPressed: () => _openSupport(context),
          child: const Text('Necesito ayuda'),
        ),
      ],
    ),
  );
}
