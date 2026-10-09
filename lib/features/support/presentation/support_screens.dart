import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/navigation.dart';
import '../../../widgets/shop_widgets.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});
  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? topic;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Centro de ayuda',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.softGreen,
          child: Icon(Icons.help_outline, color: AppColors.green, size: 32),
        ),
        const SizedBox(height: 18),
        const Text(
          '¿Cómo podemos ayudarte?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige una opción y conversemos.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ...List.generate(
          3,
          (index) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              [
                Icons.inventory_2_outlined,
                Icons.credit_card,
                Icons.person_outline,
              ][index],
              color: AppColors.green,
            ),
            title: Text(
              [
                'Ayuda con mi pedido',
                'Pagos y reembolsos',
                'Hablar con un asesor',
              ][index],
            ),
            subtitle: Text(
              [
                'Consulta entregas, cambios o devoluciones',
                'Resuelve dudas sobre tus pagos',
                'Atención de lunes a sábado',
              ][index],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                setState(() => topic = index == 2 ? 'asesor' : 'consulta'),
          ),
        ),
        if (topic != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  topic == 'asesor'
                      ? 'Simulación: te conectaremos con un asesor en unos minutos.'
                      : 'Simulación: seleccionamos tu consulta. Un asesor revisará tu caso.',
                ),
                TextButton(
                  onPressed: () => setState(() => topic = null),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => goHome(context),
          child: const Text('Volver al Inicio'),
        ),
      ],
    ),
  );
}

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});
  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool retrying = false;
  Future<void> retry() async {
    setState(() => retrying = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    goHome(context);
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Conexión',
    child: retrying
        ? const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Reconectando…'),
              ],
            ),
          )
        : EmptyState(
            icon: Icons.wifi_off_outlined,
            title: 'Sin conexión',
            message: 'Revisa tu conexión a internet e inténtalo nuevamente. Pantalla de demostración.',
            action: 'Reintentar',
            onAction: retry,
          ),
  );
}
