import 'package:flutter/material.dart';

import '../screens/shop_shell.dart';

void goHome(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute<void>(builder: (_) => const ShopShell()),
  (_) => false,
);
