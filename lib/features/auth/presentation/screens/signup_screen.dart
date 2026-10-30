import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/validators/validators.dart';
import '../../../../core/network/api_client.dart';
import '../../../../app/models/shop_models.dart';
import '../../../../app/state/shop_state.dart';
import '../../../../shared/widgets/line_icons.dart';
import '../../../../shared/widgets/shop_widgets.dart';
import '../../../cart/presentation/screens/cart_screen.dart';

import '../auth_flow.dart';
import '../widgets/account_switch.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.returnOnSuccess = false});
  final bool returnOnSuccess;
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final form = GlobalKey<FormState>();
  String name = '',
      surname = '',
      countryCode = '+51',
      customCountryCode = '',
      document = '',
      email = '',
      phone = '',
      password = '',
      documentType = 'DNI';
  bool privacy = false, hidden = true, submitting = false;
  String get dialCode =>
      countryCode == 'other' ? '+$customCountryCode' : countryCode;
  String get fullPhone => '$dialCode$phone';
  String? validateNamePart(String? value) =>
      (value ?? '').trim().isEmpty ? 'Completa este campo.' : null;
  Future<void> register() async {
    if (!form.currentState!.validate()) return;
    if (!privacy) {
      feedback(context, 'Debes aceptar la Política de Privacidad.');
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => submitting = true);
    final state = ShopScope.of(context);
    try {
      if (state.authRepository != null) {
        await state.registerRemote(
          email: email.trim(),
          name: '${name.trim()} ${surname.trim()}',
          password: password,
          phone: fullPhone,
          documentType: documentType,
          documentNumber: document,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        state.login(
          account: AppUser(
            name: '${name.trim()} ${surname.trim()}',
            document: '$documentType $document',
            email: email.trim(),
            phone: fullPhone,
          ),
        );
      }
      if (!mounted) return;
      widget.returnOnSuccess
          ? Navigator.pop(context, true)
          : enterShop(context);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.statusCode == 409
                  ? 'Este correo ya tiene una cuenta. Inicia sesi\u00f3n o usa otro correo.'
                  : 'No pudimos crear la cuenta. Verifica tus datos e intenta nuevamente.',
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Nombres'),
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: fieldDecoration('Nombres'),
                                  textCapitalization: TextCapitalization.words,
                                  validator: validateNamePart,
                                  onChanged: (value) => name = value,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                fieldLabel('Apellidos'),
                                TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  decoration: fieldDecoration('Apellidos'),
                                  textCapitalization: TextCapitalization.words,
                                  validator: validateNamePart,
                                  onChanged: (value) => surname = value,
                                ),
                              ],
                            ),
                          ),
                        ],
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
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
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
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                        decoration: fieldDecoration('correo@ejemplo.com'),
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => email = value,
                      ),
                      gap,
                      fieldLabel('Teléfono'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<String>(
                              initialValue: countryCode,
                              isExpanded: true,
                              decoration: fieldDecoration('Pais'),
                              items: const [
                                DropdownMenuItem(
                                  value: '+51',
                                  child: Text('PE +51'),
                                ),
                                DropdownMenuItem(
                                  value: '+54',
                                  child: Text('AR +54'),
                                ),
                                DropdownMenuItem(
                                  value: '+56',
                                  child: Text('CL +56'),
                                ),
                                DropdownMenuItem(
                                  value: '+57',
                                  child: Text('CO +57'),
                                ),
                                DropdownMenuItem(
                                  value: '+52',
                                  child: Text('MX +52'),
                                ),
                                DropdownMenuItem(
                                  value: '+1',
                                  child: Text('US/CA +1'),
                                ),
                                DropdownMenuItem(
                                  value: '+34',
                                  child: Text('ES +34'),
                                ),
                                DropdownMenuItem(
                                  value: 'other',
                                  child: Text('Otro'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => countryCode = value!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                              decoration: fieldDecoration('Numero de telefono'),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(15),
                              ],
                              validator: (value) => (value ?? '').isEmpty
                                  ? 'Ingresa tu telefono.'
                                  : Validators.registrationPhone(
                                      '$dialCode${value ?? ''}',
                                    ),
                              onChanged: (value) => phone = value,
                            ),
                          ),
                        ],
                      ),
                      if (countryCode == 'other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                          decoration: fieldDecoration('Codigo de pais')
                              .copyWith(prefixText: '+'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (value) =>
                              RegExp(r'^[1-9][0-9]{0,2}$').hasMatch(value ?? '')
                              ? null
                              : 'Ingresa un codigo de pais valido.',
                          onChanged: (value) => customCountryCode = value,
                        ),
                      ],
                      gap,
                      fieldLabel('Contraseña'),
                      TextFormField(
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
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
                accountSwitch(
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
