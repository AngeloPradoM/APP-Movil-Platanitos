import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/navigation.dart';
import '../models/shop_models.dart';
import '../state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import 'order_screens.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod payment = PaymentMethod.wallet;
  bool processing = false, paymentError = false;
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
    final order = state.placeOrder(payment);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => SuccessScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return PageFrame(
      title: 'Finalizar compra',
      child: state.cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Tu bolsa está vacía',
              message: 'Agrega productos antes de pagar.',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    Text('✓ Envío'),
                    Text('✓ Entrega'),
                    Text(
                      '③ Pago',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'ÚLTIMO PASO',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige cómo pagar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Demostración: no se realizan cobros.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                if (paymentError)
                  EmptyState(
                    icon: Icons.error_outline,
                    title: 'No pudimos procesar tu pago.',
                    message: 'Error simulado de tarjeta. Elige otro método para continuar.',
                    action: 'Intentar nuevamente',
                    onAction: () => setState(() => paymentError = false),
                  ),
                if (paymentError)
                  OutlinedButton(
                    onPressed: () => setState(() {
                      payment = PaymentMethod.wallet;
                      paymentError = false;
                    }),
                    child: const Text('Cambiar método de pago'),
                  )
                else ...[
                  ...PaymentMethod.values.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: payment == method
                                ? AppColors.green
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              enabled: !processing,
                              leading: CircleAvatar(
                                backgroundColor: AppColors.softGreen,
                                child: Text(
                                  switch (method) {
                                    PaymentMethod.wallet => 'Y',
                                    PaymentMethod.card => 'V',
                                    PaymentMethod.cash => 'S/',
                                  },
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              title: Text(
                                method.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(switch (method) {
                                PaymentMethod.wallet =>
                                  'Escanea el QR desde tu app',
                                PaymentMethod.card =>
                                  'Visa, Mastercard o American Express',
                                PaymentMethod.cash =>
                                  'Código en agentes autorizados',
                              }, style: const TextStyle(fontSize: 12)),
                              trailing: Icon(
                                payment == method ? Icons.remove : Icons.add,
                              ),
                              onTap: () => setState(() => payment = method),
                            ),
                            if (payment == method)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: switch (method) {
                                  PaymentMethod.wallet => Column(
                                    children: [
                                      const DemoQr(),
                                      const SizedBox(height: 14),
                                      const Text('Monto a pagar'),
                                      Text(
                                        money(state.total),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        '1. Abre Yape o Plin.\n2. Escanea el código QR.\n3. Confirma el monto.\n\nQR decorativo de demostración.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  PaymentMethod.card => const DemoCardForm(),
                                  PaymentMethod.cash => const Text(
                                    'Generaremos un código de demostración válido por 24 horas para agentes KasNet, Western Union y establecimientos autorizados.',
                                  ),
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SummaryCard(
                    subtotal: state.subtotal,
                    shipping: state.shipping,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: processing ? null : pay,
                    icon: processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      processing
                          ? 'Procesando pago…'
                          : 'Pagar ${money(state.total)}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pago simulado · No ingreses datos reales',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ],
            ),
    );
  }
}

class DemoQr extends StatelessWidget {
  const DemoQr({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Código QR decorativo, no válido para pagos',
    child: SizedBox(
      width: 132,
      height: 132,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
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
  Widget build(BuildContext context) => PageFrame(
    title: 'Compra finalizada',
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: AppColors.green,
          child: Icon(Icons.check, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'COMPRA FINALIZADA',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.green,
            letterSpacing: 1.5,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '¡Gracias por tu compra!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tu orden ha sido procesada con éxito.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        OrderReceipt(order: order),
        if (order.payment == PaymentMethod.cash)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Código de pago simulado: ${order.id}\nVálido por 24 horas.',
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => TrackingScreen(order: order),
            ),
          ),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Seguir mi pedido'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => goHome(context),
          child: const Text('Volver al Inicio'),
        ),
      ],
    ),
  );
}
