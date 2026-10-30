import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

Future<void> showAppGuideDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _AppGuideDialog(),
);

class AppGuideButton extends StatelessWidget {
  const AppGuideButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Guía de la demostración',
    onPressed: () => showAppGuideDialog(context),
    icon: const Icon(Icons.help_outline),
  );
}

class _AppGuideDialog extends StatelessWidget {
  const _AppGuideDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.softGreen,
      child: Icon(Icons.menu_book_outlined, color: AppColors.darkGreen),
    ),
    title: const Text('Guía de la demo Platanitos'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _GuideNotice(),
            SizedBox(height: 20),
            _GuideHeading('Acceso de prueba'),
            Text(
              'El perfil Cliente solicita las credenciales visibles de demostración. Los otros cinco perfiles operativos tienen acceso directo.',
            ),
            SizedBox(height: 16),
            _GuideHeading('Recorrido recomendado'),
            _GuideStep(
              number: '1',
              text:
                  'Cliente: agrega un producto y completa una compra simulada.',
            ),
            _GuideStep(
              number: '2',
              text: 'Almacén: prepara el pedido y despáchalo.',
            ),
            _GuideStep(
              number: '3',
              text: 'Repartidor: confirma recojo, ruta y entrega con firma y fotografía.',
            ),
            _GuideStep(
              number: '4',
              text: 'Cliente y Atención: registra, atiende y resuelve una solicitud.',
            ),
            _GuideStep(
              number: '5',
              text: 'Administrador: revisa los indicadores consolidados.',
            ),
            _GuideStep(
              number: '6',
              text: 'Trabajador de tienda: crea y completa una reserva.',
            ),
            SizedBox(height: 16),
            _GuideHeading('Persistencia'),
            Text(
              'Android, iOS y macOS guardan la demo en SQLite. Chrome, Windows y Linux mantienen los datos mientras la aplicación permanece abierta.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  );
}

class _GuideNotice extends StatelessWidget {
  const _GuideNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.softGreen,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.science_outlined, color: AppColors.darkGreen),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Esta es una demostración académica. Los pagos, pedidos y entregas son simulados y no procesan dinero real.',
          ),
        ),
      ],
    ),
  );
}

class _GuideHeading extends StatelessWidget {
  const _GuideHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          child: Text(
            number,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
