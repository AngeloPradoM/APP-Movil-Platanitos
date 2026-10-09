import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_theme.dart';
import '../../../core/validators.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/shop_widgets.dart';
import '../../../widgets/line_icons.dart';
import '../../auth/presentation/auth_screens.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/presentation/order_screens.dart';
import '../../support/presentation/support_screens.dart';
import 'account_services_screens.dart';
import 'address_screens.dart';

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
    final state = ShopScope.of(context);
    VoidCallback open(Widget page, {AuthPrompt? private}) => private == null
        ? () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => page),
          )
        : () => openWithLogin(context, private, (_) => page);
    final options = <(String, IconData, VoidCallback, bool)>[
      (
        'Monedero',
        Icons.account_balance_wallet_outlined,
        open(const WalletScreen(), private: AuthPrompt.account),
        true,
      ),
      (
        'Puntos',
        Icons.star_outline,
        open(const PointsScreen(), private: AuthPrompt.account),
        true,
      ),
      (
        'Órdenes',
        Icons.inventory_2_outlined,
        open(const OrdersScreen(), private: AuthPrompt.orders),
        true,
      ),
      (
        'Perfil',
        Icons.person_outline,
        open(const ProfileScreen(), private: AuthPrompt.account),
        true,
      ),
      (
        'Direcciones',
        Icons.location_on_outlined,
        open(const AddressesScreen(), private: AuthPrompt.account),
        true,
      ),
      (
        'Configuración',
        Icons.settings_outlined,
        open(const OfflineScreen()),
        false,
      ),
      (
        'Membresía',
        Icons.workspace_premium_outlined,
        open(const MembershipScreen(), private: AuthPrompt.account),
        true,
      ),
      ('Resikla', Icons.recycling, open(const ResiklaScreen()), false),
      (
        'Favoritos',
        Icons.favorite_border,
        () async {
          if (await requireLogin(context, AuthPrompt.favorites)) onFavorites();
        },
        true,
      ),
      ('eGift Card', Icons.card_giftcard, open(const GiftCardScreen()), false),
      ('Ubícanos', Icons.map_outlined, open(const StoresScreen()), false),
      ('Blog', Icons.menu_book_outlined, open(const BlogScreen()), false),
      (
        'Centro de ayuda',
        Icons.help_outline,
        open(const SupportScreen()),
        false,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        if (state.signedIn)
          MemberCard(onProfile: open(const ProfileScreen()))
        else
          const GuestCard(),
        const SizedBox(height: 24),
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
                  onTap: option.$3,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.softGreen,
                              child: Icon(option.$2, color: AppColors.green),
                            ),
                            const Spacer(),
                            if (option.$4 && !state.signedIn)
                              const Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: AppColors.muted,
                                semanticLabel: 'Requiere iniciar sesión',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            option.$1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
        if (state.signedIn)
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

class GuestCard extends StatelessWidget {
  const GuestCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Hola, invitada/o',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Inicia sesión para ver tus pedidos, acumular puntos y guardar tus favoritos.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => requireLogin(context, AuthPrompt.account),
          child: const Text('Iniciar sesión'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<bool>(
              builder: (_) => const SignupScreen(returnOnSuccess: true),
            ),
          ),
          child: const Text('Crear cuenta'),
        ),
      ],
    ),
  );
}

class MemberCard extends StatelessWidget {
  const MemberCard({super.key, required this.onProfile});
  final VoidCallback onProfile;
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
    return Material(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onProfile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.green,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${user.name.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nivel ${state.membership.label} · ${state.points} puntos',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
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
  bool editing = false, saving = false;
  String name = '', email = '', phone = '', document = '';
  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ShopScope.of(context).saveProfile(
        AppUser(
          name: name.trim(),
          document: document,
          email: email.trim(),
          phone: phone,
        ),
      );
      if (!mounted) return;
      setState(() => editing = false);
      feedback(context, 'Datos actualizados correctamente');
    } on StateError catch (error) {
      if (mounted) feedback(context, error.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

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
    final address = state.defaultAddress;
    return PageFrame(
      title: 'Perfil',
      actions: [
        IconButton(
          tooltip: 'Ver bolsa',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CartPage()),
          ),
          icon: Badge(
            label: Text('${state.cartCount}'),
            isLabelVisible: state.cartCount > 0,
            child: const LineIcon(LineIcons.bag),
          ),
        ),
      ],
      child: ColoredBox(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            _ProfileCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.softGreen,
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.darkGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.name.split(' ').first}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '✓ Datos verificados',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Datos personales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Revisa la información asociada a tu cuenta.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            _ProfileCard(
              padding: editing
                  ? const EdgeInsets.all(18)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: editing
                  ? _editForm()
                  : Column(
                      children: [
                        ProfileData(
                          icon: Icons.person_outline,
                          label: 'Nombre completo',
                          value: user.name,
                        ),
                        ProfileData(
                          icon: Icons.badge_outlined,
                          label: 'Documento de identidad',
                          value: user.document,
                        ),
                        ProfileData(
                          icon: Icons.mail_outline,
                          label: 'Correo electrónico',
                          value: user.email,
                        ),
                        ProfileData(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: '+51 ${_groupPhone(user.phone)}',
                        ),
                        ProfileData(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección principal',
                          value: address?.line1 ?? 'Agrega una dirección',
                          last: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AddressesScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.darkGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tus datos están protegidos y solo se usan para gestionar tus pedidos.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            if (!editing) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                style: primaryButtonStyle,
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar datos'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: secondaryButtonStyle.copyWith(
                  foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
                ),
                onPressed: () => confirmLogout(context),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _groupPhone(String phone) => phone.length == 9
      ? '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}'
      : phone;

  Widget _editForm() => Form(
    key: form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          style: primaryButtonStyle,
          onPressed: saving ? null : save,
          child: Text(saving ? 'Guardando…' : 'Guardar cambios'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: secondaryButtonStyle,
          onPressed: saving ? null : () => setState(() => editing = false),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class ProfileData extends StatelessWidget {
  const ProfileData({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
    this.onTap,
  });
  final IconData icon;
  final String label, value;
  final bool last;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.darkGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    ),
  );
}
