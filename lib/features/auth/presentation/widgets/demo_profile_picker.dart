import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
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
    appBar: widget.canGoBack ? AppBar() : null,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FutureBuilder<List<AppUser>>(
            future: profiles,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No se pudieron cargar los perfiles locales.'),
                );
              }
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.heading ?? 'Selecciona un perfil',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Modo demostrativo · datos ficticios almacenados localmente',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  for (final profile in snapshot.data!)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(iconFor(profile.role)),
                        ),
                        title: Text(profile.role.label),
                        subtitle: Text(profile.name),
                        trailing: selectedId == profile.id
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        enabled: selectedId == null,
                        onTap: () => select(profile),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
