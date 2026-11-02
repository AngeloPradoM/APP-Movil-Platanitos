import 'package:flutter/material.dart';

import '../../../../app/state/shop_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    return PageFrame(
      title: 'Accesibilidad',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Text(
            'Ajustes de visualización',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Estos cambios ayudan a leer mejor la app. También puedes ampliar el texto desde la configuración del celular o del navegador.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alto contraste'),
            subtitle: const Text(
              'Texto y bordes más marcados. No depende solo del color.',
            ),
            value: state.highContrast,
            onChanged: state.setHighContrast,
          ),
          const Divider(height: 28),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.keyboard_outlined, color: AppColors.green),
            title: Text('Teclado'),
            subtitle: Text(
              'En la web puedes recorrer botones y campos con Tab y Enter.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.text_fields, color: AppColors.green),
            title: Text('Tamaño de texto'),
            subtitle: Text(
              'La app respeta el tamaño del sistema hasta el 200 %.',
            ),
          ),
        ],
      ),
    );
  }
}
