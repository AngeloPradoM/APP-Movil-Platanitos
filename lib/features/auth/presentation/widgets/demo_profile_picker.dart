import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../domain/user_models.dart';

class DemoProfilePicker extends StatefulWidget {
  const DemoProfilePicker({
    super.key,
    required this.onSuccess,
    this.heading,
    this.canGoBack = false,
  });

  final VoidCallback onSuccess;
  final String? heading;
  final bool canGoBack;

  @override
  State<DemoProfilePicker> createState() => _DemoProfilePickerState();
}

class _DemoProfilePickerState extends State<DemoProfilePicker> {
  Future<List<AppUser>>? profiles;
  String? selectedId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    profiles ??= ShopScope.of(context).demoProfiles();
  }

  Future<void> select(AppUser profile) async {
    setState(() => selectedId = profile.id);
    try {
      await ShopScope.of(context).loginDemo(profile.id!);
      if (mounted) widget.onSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => selectedId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el perfil de demostración.'),
        ),
      );
    }
  }

  IconData iconFor(UserRole role) => switch (role) {
    UserRole.cliente => Icons.shopping_bag_outlined,
    UserRole.almacen => Icons.inventory_2_outlined,
    UserRole.repartidor => Icons.local_shipping_outlined,
    UserRole.atencionCliente => Icons.support_agent_outlined,
    UserRole.administrador => Icons.admin_panel_settings_outlined,
    UserRole.trabajadorTienda => Icons.store_outlined,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: softBackground,
    appBar: widget.canGoBack
        ? AppBar(backgroundColor: softBackground, elevation: 0)
        : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FutureBuilder<List<AppUser>>(
            future: profiles,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudieron cargar los perfiles locales.',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                children: [
                  SizedBox(height: widget.canGoBack ? 8 : 24),
                  const Center(child: BrandLogo()),
                  const SizedBox(height: 2),
                  Text(
                    widget.heading ?? 'Selecciona un perfil',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D4550),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Modo demostrativo · datos ficticios almacenados localmente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 28),
                  for (final profile in snapshot.data!) ...[
                    _ProfileTile(
                      profile: profile,
                      icon: iconFor(profile.role),
                      loading: selectedId == profile.id,
                      enabled: selectedId == null,
                      onTap: () => select(profile),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final AppUser profile;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(13));
    return Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.softGreen,
                child: Icon(icon, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.role.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
