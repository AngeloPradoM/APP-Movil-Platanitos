import 'package:flutter/material.dart';

import '../../../app/state/shop_state.dart';
import '../../administration/presentation/screens/role_home.dart';

import './screens/login_screen.dart';

void enterShop(BuildContext context) => Navigator.of(context)
    .pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RoleHome()),
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
