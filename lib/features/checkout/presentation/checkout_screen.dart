import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/navigation.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/line_icons.dart';
import '../../../widgets/shop_widgets.dart';
import '../../account/presentation/address_screens.dart';
import '../../orders/presentation/order_screens.dart';

const _steps = ['Envío', 'Entrega', 'Pago'];

String _shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int step = 0;
  String? addressId;
  PaymentMethod payment = PaymentMethod.wallet;
  bool processing = false, paymentError = false;

  ShippingAddress? selectedAddress(ShopState state) {
    for (final address in state.addresses) {
      if (address.id == addressId) return address;
    }
    return state.defaultAddress;
  }

  Future<void> addAddress() async {
    final state = ShopScope.of(context);
    final before = state.addresses.map((address) => address.id).toSet();
    if (!await openAddressForm(context) || !mounted) return;
    final added = state.addresses
        .where((address) => !before.contains(address.id))
        .firstOrNull;
    if (added != null) setState(() => addressId = added.id);
  }

  Future<void> pay() async {
    if (processing || ShopScope.of(context).cart.isEmpty) return;
    setState(() => processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (payment == PaymentMethod.card) {
      setState(() {
        processing = false;
        paymentError = true;
      });
      return;
    }
    final state = ShopScope.of(context);
    if (state.cart.isEmpty) {
      setState(() => processing = false);
      return;
    }
    final ShopOrder order;
    try {
      order = await state.checkout(payment, address: selectedAddress(state));
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() => processing = false);
      feedback(context, error.message);
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => SuccessScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    final address = selectedAddress(state);
    final current = address == null ? 0 : step;
    final Widget action = switch (current) {
      0 => FilledButton(
        style: primaryButtonStyle,
        onPressed: address == null ? null : () => setState(() => step = 1),
        child: const Text('Continuar'),
      ),
      1 => FilledButton(
        style: primaryButtonStyle,
        onPressed: () => setState(() => step = 2),
        child: const Text('Continuar al pago'),
      ),
      _ => FilledButton(
        style: primaryButtonStyle,
        onPressed: processing ? null : pay,
        child: processing
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('Procesando pago…'),
                ],
              )
            : Text('Pagar ${money(state.total)}'),
      ),
    };
    return PopScope(
      canPop: current == 0 || processing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => step = current - 1);
      },
      child: PageFrame(
        title: 'Finalizar Compra',
        actions: [
          IconButton(
            tooltip: 'Volver a la bolsa',
            onPressed: () => Navigator.maybePop(context),
            icon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const LineIcon(LineIcons.bag),
            ),
          ),
        ],
        bottom: state.cart.isEmpty ? null : action,
        child: state.cart.isEmpty
            ? const EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Tu bolsa está vacía',
                message: 'Agrega productos antes de pagar.',
              )
            : ColoredBox(
                color: softBackground,
                child: Column(
                  children: [
                    CheckoutSteps(
                      current: current,
                      onSelect: processing
                          ? null
                          : (value) => setState(() => step = value),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: switch (current) {
                          0 => _shippingStep(state, address),
                          1 => _deliveryStep(state, address!),
                          _ => _paymentStep(state),
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _title(String title, String subtitle) => [
    Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 4),
    Text(
      subtitle,
      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
    ),
    const SizedBox(height: 18),
  ];

  List<Widget> _shippingStep(ShopState state, ShippingAddress? selected) => [
    ..._title(
      'Dirección de envío',
      'Elige dónde quieres recibir tu pedido o escribe una nueva dirección.',
    ),
    if (state.addresses.isEmpty)
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fieldBorderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.location_off_outlined, color: AppColors.muted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no tienes direcciones guardadas. Agrega una para continuar.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      )
    else
      for (final address in state.addresses)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AddressCard(
            address: address,
            selected: address.id == selected?.id,
            onTap: () => setState(() => addressId = address.id),
            onEdit: () => openAddressForm(context, initial: address),
          ),
        ),
    const SizedBox(height: 4),
    OutlinedButton.icon(
      style: secondaryButtonStyle.copyWith(
        foregroundColor: const WidgetStatePropertyAll(AppColors.darkGreen),
      ),
      onPressed: addAddress,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Agregar nueva dirección'),
    ),
  ];

  List<Widget> _deliveryStep(ShopState state, ShippingAddress address) {
    final now = DateTime.now();
    final from = now.add(const Duration(days: 6));
    final to = now.add(const Duration(days: 8));
    return [
      ..._title('Entrega', 'Revisa cuándo y dónde llegará tu pedido.'),
      _Panel(
        highlighted: true,
        child: Row(
          children: [
            const _IconTile(icon: Icons.local_shipping_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery a domicilio',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Llega entre el ${_shortDate(from)} y el ${_shortDate(to)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              money(state.shipping),
              style: const TextStyle(
                color: AppColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _Panel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _IconTile(icon: Icons.location_on_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviar a ${address.label}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(address.line1, style: const TextStyle(fontSize: 13)),
                  Text(
                    address.region,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Recibe: ${address.recipient}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.darkGreen),
              onPressed: () => setState(() => step = 0),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Resumen de tu pedido',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _Panel(
        child: Column(
          children: [
            for (final item in state.cart)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox.square(
                        dimension: 48,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Talla ${item.size} ${item.system.name.toUpperCase()} · Cant. ${item.quantity}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(item.subtotal),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SummaryCard(subtotal: state.subtotal, shipping: state.shipping),
    ];
  }

  List<Widget> _paymentStep(ShopState state) => [
    const Text(
      'Método de Pago',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 16),
    if (paymentError) ...[
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: .3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No pudimos procesar tu pago.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Error simulado de tarjeta. Elige otro método para continuar; tu bolsa sigue intacta.',
              style: TextStyle(fontSize: 12.5),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.darkGreen,
                padding: EdgeInsets.zero,
              ),
              onPressed: () => setState(() {
                payment = PaymentMethod.wallet;
                paymentError = false;
              }),
              child: const Text('Cambiar método de pago'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
    ],
    for (final method in PaymentMethod.values)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PaymentOption(
          method: method,
          expanded: payment == method,
          onTap: processing
              ? null
              : () => setState(() {
                  payment = method;
                  paymentError = false;
                }),
          child: switch (method) {
            PaymentMethod.wallet => Column(
              children: [
                const Text(
                  'Escanea el código QR desde tu app preferida para realizar el pago.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: fieldBorderColor),
                  ),
                  child: const DemoQr(size: 76),
                ),
                const SizedBox(height: 12),
                Text(
                  'Monto a pagar: ${money(state.total)}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            PaymentMethod.card => const DemoCardForm(),
            PaymentMethod.cash => const Text(
              'Generaremos un código de demostración válido por 24 horas para agentes KasNet, Western Union y establecimientos autorizados.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          },
        ),
      ),
    const SizedBox(height: 4),
    const Text(
      'Pago simulado · No ingreses datos reales',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.muted, fontSize: 11.5),
    ),
  ];
}

class CheckoutSteps extends StatelessWidget {
  const CheckoutSteps({super.key, required this.current, this.onSelect});
  final int current;

  /// Permite volver a un paso ya completado.
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < _steps.length; index++) ...[
            if (index > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.fromLTRB(4, 13, 4, 0),
                  color: index <= current
                      ? AppColors.darkGreen
                      : fieldBorderColor,
                ),
              ),
            _StepDot(
              label: _steps[index],
              done: index < current,
              active: index == current,
              onTap: index < current && onSelect != null
                  ? () => onSelect!(index)
                  : null,
            ),
          ],
        ],
      ),
    ),
  );
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.done,
    required this.active,
    this.onTap,
  });
  final String label;
  final bool done, active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    return Semantics(
      label:
          'Paso $label${done
              ? ', completado'
              : active
              ? ', actual'
              : ''}',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.darkGreen : Colors.white,
                  border: Border.all(
                    color: reached ? AppColors.darkGreen : fieldBorderColor,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: reached ? FontWeight.w600 : FontWeight.w500,
                  color: reached ? AppColors.darkGreen : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentOption extends StatelessWidget {
  const PaymentOption({
    super.key,
    required this.method,
    required this.expanded,
    required this.onTap,
    required this.child,
  });
  final PaymentMethod method;
  final bool expanded;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: expanded ? AppColors.darkGreen : fieldBorderColor,
        width: expanded ? 1.4 : 1,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: Material(
              color: expanded ? AppColors.softGreen : Colors.white,
              child: InkWell(
                onTap: onTap,
                hoverColor: AppColors.green.withValues(alpha: .05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      _methodIcon(method),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: expanded
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: expanded
                                ? AppColors.darkGreen
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: expanded ? AppColors.darkGreen : AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ),
  );

  Widget _methodIcon(PaymentMethod method) => switch (method) {
    PaymentMethod.wallet => Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2430),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.qr_code_2, size: 18, color: Color(0xFFC08BFF)),
    ),
    PaymentMethod.card => const Icon(Icons.credit_card_outlined),
    PaymentMethod.cash => const Icon(Icons.payments_outlined),
  };
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.highlighted = false});
  final Widget child;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: highlighted ? AppColors.softGreen : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: highlighted ? AppColors.darkGreen : fieldBorderColor,
        width: highlighted ? 1.4 : 1,
      ),
    ),
    child: child,
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Icon(icon, color: AppColors.darkGreen, size: 20),
  );
}

class DemoQr extends StatelessWidget {
  const DemoQr({super.key, this.size = 132});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Código QR decorativo, no válido para pagos',
    child: SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        crossAxisCount: 7,
        mainAxisSpacing: size / 66,
        crossAxisSpacing: size / 66,
        children: List.generate(
          49,
          (index) => ColoredBox(
            color: (index * 7 + index * index) % 5 < 2
                ? AppColors.ink
                : Colors.white,
          ),
        ),
      ),
    ),
  );
}

class DemoCardForm extends StatelessWidget {
  const DemoCardForm({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Datos ficticios · Este método simula un error de pago.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: '0000 0000 0000 0000',
        readOnly: true,
        decoration: const InputDecoration(
          labelText: 'Número de tarjeta de prueba',
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        initialValue: 'USUARIO DEMO',
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Titular de prueba'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: '12 / 30',
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Vencimiento'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: '000',
              readOnly: true,
              decoration: const InputDecoration(labelText: 'CVV ficticio'),
            ),
          ),
        ],
      ),
    ],
  );
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.order});
  final ShopOrder order;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            children: [
              const OrderCheckBadge(),
              const SizedBox(height: 22),
              const Text(
                '¡Gracias por tu compra!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu orden ha sido procesada con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 26),
              OrderReceipt(order: order),
              if (order.payment == PaymentMethod.cash) ...[
                const SizedBox(height: 12),
                OrderCard(
                  color: AppColors.softGreen,
                  child: Text(
                    'Código de pago simulado: ${order.id}\nVálido por 24 horas.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              const OrderFootnote(
                'Hemos enviado un correo electrónico de confirmación con los detalles y la factura de tu pedido.',
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                style: outlineGreenButtonStyle,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TrackingScreen(order: order),
                  ),
                ),
                child: const Text('Seguir mi pedido'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: primaryButtonStyle,
                onPressed: () => goHome(context),
                child: const Text('Volver al Inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
