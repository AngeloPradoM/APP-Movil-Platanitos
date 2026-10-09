import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_theme.dart';
import '../../../core/validators.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/shop_models.dart';
import '../../../shared/state/shop_state.dart';
import '../../../widgets/line_icons.dart';
import '../../../widgets/shop_widgets.dart';
import '../../../app/shop_shell.dart';
import '../../cart/presentation/cart_screen.dart';

void enterShop(BuildContext context) => Navigator.of(context)
    .pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ShopShell()),
      (_) => false,
    );

/// Texto que explica por qué se pide iniciar sesión en medio de la compra.
class AuthPrompt {
  const AuthPrompt({
    required this.eyebrow,
    required this.heading,
    required this.description,
  });
  final String eyebrow, heading, description;

  static const checkout = AuthPrompt(
    eyebrow: 'FINALIZA TU COMPRA',
    heading: 'Inicia sesión para pagar',
    description:
        'Necesitas una cuenta para completar el pago. Tu bolsa se conservará.',
  );
  static const favorites = AuthPrompt(
    eyebrow: 'TUS FAVORITOS',
    heading: 'Inicia sesión para guardar favoritos',
    description: 'Guarda los productos que te gustan y encuéntralos después.',
  );
  static const orders = AuthPrompt(
    eyebrow: 'TUS PEDIDOS',
    heading: 'Inicia sesión para ver tus pedidos',
    description: 'Revisa el estado y el seguimiento de tus compras.',
  );
  static const account = AuthPrompt(
    eyebrow: 'MI CUENTA',
    heading: 'Inicia sesión para continuar',
    description: 'Accede a tu perfil, pedidos, puntos, monedero y beneficios de membresía.',
  );
}

/// Abre el login cuando no hay sesión. Devuelve `true` si el usuario
/// terminó con una sesión iniciada.
Future<bool> requireLogin(BuildContext context, AuthPrompt prompt) async {
  if (ShopScope.of(context).signedIn) return true;
  final authenticated = await Navigator.push<bool>(
    context,
    MaterialPageRoute<bool>(builder: (_) => LoginScreen(prompt: prompt)),
  );
  return authenticated == true;
}

Future<bool> requireLoginForCheckout(BuildContext context) =>
    requireLogin(context, AuthPrompt.checkout);

Future<void> openWithLogin(
  BuildContext context,
  AuthPrompt prompt,
  WidgetBuilder builder,
) async {
  if (!await requireLogin(context, prompt) || !context.mounted) return;
  Navigator.push(context, MaterialPageRoute<void>(builder: builder));
}

Future<void> toggleFavoriteWithLogin(
  BuildContext context,
  int productId,
) async {
  if (!await requireLogin(context, AuthPrompt.favorites) || !context.mounted) {
    return;
  }
  ShopScope.of(context).toggleFavorite(productId);
}

Widget _accountSwitch({
  required String question,
  required String action,
  required VoidCallback onPressed,
}) => Center(
  child: TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    child: Text.rich(
      TextSpan(
        text: '$question ',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        children: [
          TextSpan(
            text: action,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    ),
  ),
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.prompt});

  /// Si existe, el login se abrió en medio de un flujo y al terminar
  /// regresa a él en lugar de reiniciar la tienda.
  final AuthPrompt? prompt;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  String email = '', password = '';
  bool hidden = true;
  bool submitting = false;
  bool get returnOnSuccess => widget.prompt != null;

  void finish() =>
      returnOnSuccess ? Navigator.pop(context, true) : enterShop(context);

  Future<void> openSignup() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => SignupScreen(returnOnSuccess: returnOnSuccess),
      ),
    );
    if (created == true && mounted) finish();
  }

  Future<void> login({bool social = false}) async {
    if (!social && !form.currentState!.validate()) return;
    final state = ShopScope.of(context);
    if (!social && state.authRepository != null) {
      setState(() => submitting = true);
      try {
        await state.loginRemote(email: email.trim(), password: password);
        if (mounted) finish();
      } on ApiException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No pudimos iniciar sesión. Verifica tus datos e inténtalo nuevamente.',
              ),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El sistema está fallando en este momento. Intenta más tarde.',
              ),
            ),
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
    finish();
  }

  Widget _socialButton(String label, Widget icon) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () => login(social: true),
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 40),
        side: const BorderSide(color: fieldBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final prompt = widget.prompt;
    return Scaffold(
      backgroundColor: softBackground,
      appBar: returnOnSuccess
          ? AppBar(backgroundColor: softBackground, elevation: 0)
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: returnOnSuccess ? 8 : 48),
                        const Center(child: BrandLogo()),
                        const SizedBox(height: 2),
                        Text(
                          prompt?.heading ?? 'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3D4550),
                          ),
                        ),
                        if (prompt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            prompt.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 56),
                        Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              fieldLabel('Correo electrónico'),
                              TextFormField(
                                decoration: fieldDecoration(
                                  'ejemplo@correo.com',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                                onChanged: (value) => email = value,
                              ),
                              const SizedBox(height: 16),
                              fieldLabel('Contraseña'),
                              TextFormField(
                                decoration: fieldDecoration(
                                  'Ingresa tu contraseña',
                                  suffix: IconButton(
                                    tooltip: hidden
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () =>
                                        setState(() => hidden = !hidden),
                                    icon: Icon(
                                      hidden
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: hintColor,
                                      size: 20,
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
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.darkGreen,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    textStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FilledButton(
                                onPressed: submitting ? null : login,
                                style: primaryButtonStyle,
                                child: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Iniciar Sesión'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(child: Divider(color: fieldBorderColor)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o ingresa con',
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: fieldBorderColor)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _socialButton(
                              'Google',
                              const Icon(Icons.g_mobiledata_rounded, size: 26),
                            ),
                            const SizedBox(width: 12),
                            _socialButton(
                              'Apple',
                              const Icon(Icons.apple, size: 20),
                            ),
                          ],
                        ),
                        if (!returnOnSuccess) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => enterShop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.muted,
                                textStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                ),
                              ),
                              child: const Text('Continuar como invitada/o'),
                            ),
                          ),
                        ],
                        const Spacer(),
                        const SizedBox(height: 24),
                        _accountSwitch(
                          question: '¿No tienes cuenta?',
                          action: 'Regístrate',
                          onPressed: openSignup,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  const SignupScreen({super.key, this.returnOnSuccess = false});
  final bool returnOnSuccess;
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
    final state = ShopScope.of(context);
    try {
      if (state.authRepository != null) {
        await state.registerRemote(
          email: email.trim(),
          name: name.trim(),
          password: password,
          phone: phone,
          documentType: documentType,
          documentNumber: document,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        state.login(
          account: AppUser(
            name: name.trim(),
            document: '$documentType $document',
            email: email.trim(),
            phone: phone,
          ),
        );
      }
      if (!mounted) return;
      widget.returnOnSuccess
          ? Navigator.pop(context, true)
          : enterShop(context);
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos crear la cuenta. Verifica tus datos e inténtalo nuevamente.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El sistema está fallando en este momento. Intenta más tarde.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  late final privacyLink = TapGestureRecognizer()
    ..onTap = () => showInfo(
      context,
      'Política de Privacidad',
      'Protegemos tus datos personales y los utilizamos para gestionar tu cuenta, compras y entregas.',
    );

  @override
  void dispose() {
    privacyLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopScope.of(context);
    const gap = SizedBox(height: 14);
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Crear Cuenta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
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
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              children: [
                const Text(
                  'Únete a Platanitos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      fieldLabel('Nombre completo'),
                      TextFormField(
                        decoration: fieldDecoration('Nombres y Apellidos'),
                        textCapitalization: TextCapitalization.words,
                        validator: Validators.name,
                        onChanged: (value) => name = value,
                      ),
                      gap,
                      fieldLabel('Tipo de documento'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 108,
                            child: DropdownButtonFormField<String>(
                              initialValue: documentType,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                              ),
                              decoration: fieldDecoration('Tipo').copyWith(
                                contentPadding: const EdgeInsets.fromLTRB(
                                  12,
                                  13,
                                  8,
                                  13,
                                ),
                              ),
                              items: ['DNI', 'CE', 'Pasaporte']
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setState(() {
                                documentType = value!;
                                document = '';
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey(documentType),
                              decoration:
                                  fieldDecoration(
                                    'Documento de identidad',
                                  ).copyWith(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 13,
                                    ),
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
                              validator: (value) =>
                                  Validators.document(value, documentType),
                              onChanged: (value) => document = value,
                            ),
                          ),
                        ],
                      ),
                      gap,
                      fieldLabel('Correo electrónico'),
                      TextFormField(
                        decoration: fieldDecoration('correo@ejemplo.com'),
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => email = value,
                      ),
                      gap,
                      fieldLabel('Teléfono'),
                      TextFormField(
                        decoration: fieldDecoration('987 654 321'),
                        validator: Validators.phone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        onChanged: (value) => phone = value,
                      ),
                      gap,
                      fieldLabel('Contraseña'),
                      TextFormField(
                        decoration: fieldDecoration(
                          'Mínimo 8 caracteres',
                          suffix: IconButton(
                            tooltip: hidden
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(
                              hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: hintColor,
                              size: 20,
                            ),
                          ),
                        ),
                        obscureText: hidden,
                        validator: Validators.password,
                        onChanged: (value) => password = value,
                      ),
                      const SizedBox(height: 16),
                      MergeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: privacy,
                                activeColor: AppColors.darkGreen,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (value) =>
                                    setState(() => privacy = value!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'Acepto la ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: AppColors.ink,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Política de Privacidad',
                                      recognizer: privacyLink,
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' y el Tratamiento de mis Datos Personales.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: submitting ? null : register,
                        style: primaryButtonStyle,
                        child: Text(
                          submitting ? 'Creando cuenta…' : 'Crear Cuenta',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _accountSwitch(
                  question: '¿Ya tienes cuenta?',
                  action: 'Inicia Sesión',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
