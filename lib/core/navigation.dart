import 'package:flutter/material.dart';

import '../app/shop_shell.dart';

void goHome(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute<void>(builder: (_) => const ShopShell()),
  (_) => false,
);
