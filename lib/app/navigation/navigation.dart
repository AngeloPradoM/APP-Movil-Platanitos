import 'package:flutter/material.dart';

import '../../features/administration/presentation/screens/role_home.dart';

void goHome(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute<void>(builder: (_) => const RoleHome()),
  (_) => false,
);
