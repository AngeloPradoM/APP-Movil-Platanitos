import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/validators.dart';

import '../widgets/auth_layout.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final form = GlobalKey<FormState>();
  String email = '';
  bool sent = false;
  @override
  Widget build(BuildContext context) => AuthLayout(
    back: true,
    heading: sent ? 'Revisa tu correo' : '¿Olvidaste tu contraseña?',
    eyebrow: sent ? 'ENLACE ENVIADO' : 'RECUPERA TU ACCESO',
    description: sent
        ? 'Simulamos el envío de un enlace a $email. Revisa también tu bandeja de spam.'
        : 'Ingresa el correo asociado a tu cuenta y te enviaremos instrucciones.',
    children: sent
        ? [
            const Icon(Icons.check_circle, color: AppColors.green, size: 72),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver al inicio de sesión'),
            ),
            TextButton(
              onPressed: () => setState(() => sent = false),
              child: const Text('Enviar nuevamente'),
            ),
          ]
        : [
            Form(
              key: form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
                onChanged: (value) => email = value,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) setState(() => sent = true);
              },
              child: const Text('Enviar enlace de recuperación'),
            ),
          ],
  );
}
