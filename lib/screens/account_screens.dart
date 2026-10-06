import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../models/shop_models.dart';
import '../state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import 'auth_screens.dart';
import 'order_screens.dart';
import 'support_screens.dart';

Future<void> confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Deseas cerrar sesión?'),
      content: const Text(
        'Tendrás que ingresar nuevamente para acceder a tu cuenta.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  ShopScope.of(context).logout();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.onFavorites});
  final VoidCallback onFavorites;
  @override
  Widget build(BuildContext context) {
    final options = <(String, IconData, VoidCallback?)>[
      ('Monedero', Icons.account_balance_wallet_outlined, null),
      ('Puntos', Icons.star_outline, null),
      (
        'Órdenes',
        Icons.inventory_2_outlined,
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
        ),
      ),
      (
        'Perfil',
        Icons.person_outline,
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
        ),
      ),
      (
        'Configuración',
        Icons.settings_outlined,
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const OfflineScreen()),
        ),
      ),
      ('Membresía', Icons.workspace_premium_outlined, null),
      ('Resikla', Icons.recycling, null),
      ('Favoritos', Icons.favorite_border, onFavorites),
      ('eGift Card', Icons.card_giftcard, null),
      ('Ubícanos', Icons.map_outlined, null),
      ('Blog', Icons.menu_book_outlined, null),
      (
        'Centro de ayuda',
        Icons.help_outline,
        () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SupportScreen()),
        ),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          '¿Qué necesitas hoy?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gestiona tu cuenta, beneficios y servicios.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 700 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent:
                  132 + (MediaQuery.textScalerOf(context).scale(1) - 1) * 90,
            ),
            itemBuilder: (_, index) {
              final option = options[index];
              return Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap:
                      option.$3 ??
                      () => showInfo(
                        context,
                        option.$1,
                        'Esta opción aparece en el prototipo, pero todavía no tiene un servicio definido.',
                      ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.softGreen,
                          child: Icon(option.$2, color: AppColors.green),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          option.$1,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => confirmLogout(context),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(color: AppColors.danger),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Platanitos App · Versión 1.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  bool editing = false;
  String name = '', email = '', phone = '', document = '';
  void edit() {
    final user = ShopScope.of(context).user;
    setState(() {
      name = user.name;
      email = user.email;
      phone = user.phone;
      document = user.document;
      editing = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context), user = state.user;
    final initials = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0])
        .join()
        .toUpperCase();
    return PageFrame(
      title: 'Perfil',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.softGreen,
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hola, ${user.name.split(' ').first}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            '✓ Datos de demostración',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.green, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Datos personales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  if (editing) ...[
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: Validators.name,
                      onChanged: (value) => name = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: document,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Documento'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: email,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => email = value,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: phone,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      validator: Validators.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      onChanged: (value) => phone = value,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        if (!form.currentState!.validate()) return;
                        state.updateUser(
                          AppUser(
                            name: name.trim(),
                            document: document,
                            email: email.trim(),
                            phone: phone,
                          ),
                        );
                        setState(() => editing = false);
                        feedback(context, 'Datos actualizados correctamente');
                      },
                      child: const Text('Guardar cambios'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => editing = false),
                      child: const Text('Cancelar'),
                    ),
                  ] else ...[
                    ProfileData(label: 'Nombre', value: user.name),
                    ProfileData(label: 'Documento', value: user.document),
                    ProfileData(label: 'Correo', value: user.email),
                    ProfileData(label: 'Teléfono', value: '+51 ${user.phone}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const ListTile(
            tileColor: AppColors.softGreen,
            leading: Icon(Icons.verified_user_outlined, color: AppColors.green),
            subtitle: Text(
              'Tus datos están protegidos y se conservan en memoria durante esta demostración.',
            ),
          ),
          const SizedBox(height: 20),
          if (!editing)
            OutlinedButton(onPressed: edit, child: const Text('Editar datos')),
          TextButton(
            onPressed: () => confirmLogout(context),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileData extends StatelessWidget {
  const ProfileData({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Divider(),
      ],
    ),
  );
}
