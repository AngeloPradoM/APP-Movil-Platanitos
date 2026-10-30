import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/network/api_client.dart';
import '../../../../app/models/shop_models.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/shop_widgets.dart';

import '../auth_flow.dart';
import '../widgets/account_switch.dart';
import '../widgets/demo_profile_picker.dart';
import './recovery_screen.dart';
import './signup_screen.dart';

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
  static const demoClientPassword = 'Cliente123';
  String email = '', password = '';
  bool hidden = true;
  bool submitting = false;
  AppUser? demoClientProfile;
  bool get returnOnSuccess => widget.prompt != null;
  bool get isDemoClientLogin => demoClientProfile != null;
  bool get showBackButton => returnOnSuccess || isDemoClientLogin;

  void finish() =>
      returnOnSuccess ? Navigator.pop(context, true) : enterShop(context);

  void openDemoClientLogin(AppUser profile) {
    setState(() {
      demoClientProfile = profile;
      email = profile.email;
      password = '';
      hidden = true;
    });
  }

  void closeDemoClientLogin() {
    form.currentState?.reset();
    setState(() {
      demoClientProfile = null;
      email = '';
      password = '';
    });
  }

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
    final demoProfile = demoClientProfile;
    if (!social && demoProfile != null) {
      if (email.trim().toLowerCase() != demoProfile.email.toLowerCase() ||
          password != demoClientPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo o contraseña incorrectos. Usa las credenciales de demostración.',
            ),
          ),
        );
        return;
      }
      setState(() => submitting = true);
      try {
        await state.loginDemo(demoProfile.id!);
        if (mounted) finish();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo iniciar la sesión de Cliente.'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => submitting = false);
      }
      return;
    }
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
    final appState = ShopScope.of(context);
    if (appState.isDemoMode && !isDemoClientLogin) {
      return DemoProfilePicker(
        heading: widget.prompt?.heading,
        canGoBack: returnOnSuccess,
        onSuccess: finish,
        onClientSelected: openDemoClientLogin,
      );
    }
    final prompt = widget.prompt;
    return Scaffold(
      backgroundColor: softBackground,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: softBackground,
              elevation: 0,
              leading: isDemoClientLogin
                  ? BackButton(onPressed: closeDemoClientLogin)
                  : null,
            )
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
                        SizedBox(height: showBackButton ? 8 : 48),
                        const Center(child: BrandLogo()),
                        const SizedBox(height: 2),
                        Text(
                          isDemoClientLogin
                              ? 'Iniciar sesión como Cliente'
                              : prompt?.heading ?? 'Iniciar sesión',
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
                        if (isDemoClientLogin) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Credenciales de demostración',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                SizedBox(height: 6),
                                SelectableText('Correo: cliente@demo.local'),
                                SelectableText('Contraseña: Cliente123'),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: isDemoClientLogin ? 24 : 56),
                        Form(
                          key: form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              fieldLabel('Correo electrónico'),
                              TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                initialValue: isDemoClientLogin
                                    ? demoClientProfile!.email
                                    : null,
                                decoration: fieldDecoration(
                                  'ejemplo@correo.com',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                                onChanged: (value) => email = value,
                              ),
                              const SizedBox(height: 16),
                              fieldLabel('Contraseña'),
                              TextFormField(
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
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
                                textInputAction: TextInputAction.go,
                                onFieldSubmitted: (_) {
                                  if (!submitting) login();
                                },
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
                        if (!isDemoClientLogin && appState.isDemoMode) ...[
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
                                const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _socialButton(
                                'Apple',
                                const Icon(Icons.apple, size: 20),
                              ),
                            ],
                          ),
                        ],
                        if (!returnOnSuccess && !isDemoClientLogin) ...[
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
                        accountSwitch(
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
