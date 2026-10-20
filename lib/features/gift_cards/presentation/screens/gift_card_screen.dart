import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/validators.dart';
import '../../../../app/data/demo_data.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../auth/presentation/auth_flow.dart';

import '../../../../shared/widgets/info_cards.dart';

class GiftCardScreen extends StatefulWidget {
  const GiftCardScreen({super.key});
  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  final form = GlobalKey<FormState>();
  double amount = giftCardAmounts[1];
  String name = '', email = '', message = '';
  bool sending = false;

  Future<void> send() async {
    if (sending || !form.currentState!.validate()) return;
    if (!await requireLogin(context, AuthPrompt.account) || !mounted) return;
    setState(() => sending = true);
    try {
      final code = await ShopScope.of(context).sendGiftCard(
        amount: amount,
        recipientName: name.trim(),
        recipientEmail: email.trim(),
        message: message.trim(),
      );
      if (!mounted) return;
      await showInfo(
        context,
        'eGift Card enviada',
        'Código: $code\n\nEnviamos ${money(amount)} a ${email.trim()} (demostración, sin cobro ni correo real).',
      );
      if (!mounted) return;
      form.currentState!.reset();
      setState(() {
        name = '';
        email = '';
        message = '';
      });
    } on StateError catch (error) {
      if (mounted) feedback(context, error.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'eGift Card',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        HighlightCard(
          label: 'platanitos eGift Card',
          value: money(amount),
          caption: name.trim().isEmpty ? 'Para alguien especial' : 'Para $name',
        ),
        const SectionTitle('Elige el monto'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: giftCardAmounts
              .map(
                (value) => ChoiceChip(
                  label: Text(money(value)),
                  selected: amount == value,
                  onSelected: (_) => setState(() => amount = value),
                ),
              )
              .toList(),
        ),
        const SectionTitle('¿Para quién es?'),
        Form(
          key: form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre de quien recibe',
                ),
                validator: Validators.name,
                onChanged: (value) => setState(() => name = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Correo de quien recibe',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                onChanged: (value) => email = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mensaje (opcional)',
                ),
                maxLength: 120,
                maxLines: 3,
                onChanged: (value) => message = value,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: sending ? null : send,
                icon: const Icon(Icons.card_giftcard),
                label: Text(sending ? 'Enviando…' : 'Enviar eGift Card'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Envío simulado · No se realizan cobros.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
