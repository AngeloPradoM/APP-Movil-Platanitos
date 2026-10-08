import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../data/api_client.dart';
import '../models/shop_models.dart';
import '../state/shop_state.dart';
import '../widgets/shop_widgets.dart';
import 'shop_shell.dart';

void enterShop(BuildContext context) => Navigator.of(context)
    .pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ShopShell()),
      (_) => false,
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  String email = '', password = '';
  bool hidden = true;
  bool submitting = false;

  Future<void> login({bool social = false}) async {
    if (!social && !form.currentState!.validate()) return;
    final state = ShopScope.of(context);
    if (!social && state.authRepository != null) {
      setState(() => submitting = true);
      try {
        await state.loginRemote(email: email.trim(), password: password);
        if (mounted) enterShop(context);
      } on ApiException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No pudimos iniciar sesión. Verifica tus datos e inténtalo nuevamente.')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El sistema está fallando en este momento. Intenta más tarde.')),
          );
        }
      } finally {
        if (mounted) setState(() => submitting = false);
      }
      return;
    }
    state.login(
      account: social
          ? null
          : AppUser(
              name: state.user.name,
              document: state.user.document,
              email: email.trim(),
              phone: state.user.phone,
            ),
    );
    enterShop(context);
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    heading: 'Inicia sesión',
    eyebrow: 'BIENVENIDA DE NUEVO',
    description: 'Ingresa tus datos para continuar comprando.',
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'nombre@correo.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
              onChanged: (value) => email = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: hidden,
              validator: Validators.password,
              onChanged: (value) => password = value,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RecoveryScreen(),
                  ),
                ),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            FilledButton(
              onPressed: submitting ? null : login,
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Center(child: Text('o continúa con')),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => login(social: true),
              child: const Text('G  Google'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => login(social: true),
              child: const Text('●  Apple'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => enterShop(context),
        child: const Text('Continuar como invitada/o'),
      ),
      const SizedBox(height: 20),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
        ),
        child: const Text('¿No tienes cuenta? Regístrate'),
      ),
      const Center(
        child: Text(
          'Acceso de demostración · Sin autenticación real',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Al continuar aceptas nuestros Términos y Condiciones.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
    ],
  );
}

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.heading,
    required this.eyebrow,
    required this.description,
    required this.children,
    this.back = false,
  });
  final String heading, eyebrow, description;
  final List<Widget> children;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: back ? AppBar() : null,
    body: SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [AppColors.softGreen, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              children: [
                const Center(child: BrandLogo()),
                const SizedBox(height: 40),
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 28),
                ...children,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final form = GlobalKey<FormState>();
  String name = '',
      document = '',
      email = '',
      phone = '',
      password = '',
      documentType = 'DNI';
  bool privacy = false, hidden = true, submitting = false;
  Future<void> register() async {
    if (!form.currentState!.validate()) return;
    if (!privacy) {
      feedback(context, 'Debes aceptar la Política de Privacidad.');
      return;
    }
    setState(() => submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    ShopScope.of(context).login(
      account: AppUser(
        name: name.trim(),
        document: '$documentType $document',
        email: email.trim(),
        phone: phone,
      ),
    );
    enterShop(context);
  }

  @override
  Widget build(BuildContext context) => AuthLayout(
    back: true,
    heading: 'Crea tu cuenta',
    eyebrow: 'ÚNETE A PLATANITOS',
    description: 'Completa tus datos y disfruta una experiencia hecha para ti.',
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: Validators.name,
              onChanged: (value) => name = value,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: documentType,
              decoration: const InputDecoration(labelText: 'Tipo de documento'),
              items: ['DNI', 'CE', 'Pasaporte']
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                documentType = value!;
                document = '';
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey(documentType),
              decoration: const InputDecoration(
                labelText: 'Número de documento',
              ),
              keyboardType: documentType == 'DNI'
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  documentType == 'DNI'
                      ? RegExp(r'\d')
                      : RegExp(r'[a-zA-Z0-9]'),
                ),
                LengthLimitingTextInputFormatter(
                  documentType == 'DNI' ? 8 : 12,
                ),
              ],
              validator: (value) => Validators.document(value, documentType),
              onChanged: (value) => document = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
              validator: Validators.email,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) => email = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Teléfono'),
              validator: Validators.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              onChanged: (value) => phone = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Contraseña',
                suffixIcon: IconButton(
                  tooltip: 'Mostrar u ocultar contraseña',
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: hidden,
              validator: Validators.password,
              onChanged: (value) => password = value,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: privacy,
              onChanged: (value) => setState(() => privacy = value!),
              title: const Text(
                'Acepto la Política de Privacidad y el Tratamiento de Datos Personales.',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextButton(
              onPressed: () => showInfo(
                context,
                'Política de Privacidad',
                'Protegemos tus datos personales y los utilizamos para gestionar tu cuenta, compras y entregas. En esta demostración se conservan únicamente en memoria.',
              ),
              child: const Text('Leer Política de Privacidad'),
            ),
            FilledButton(
              onPressed: submitting ? null : register,
              child: Text(submitting ? 'Creando cuenta…' : 'Crear cuenta'),
            ),
          ],
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('¿Ya tienes cuenta? Inicia sesión'),
      ),
    ],
  );
}
