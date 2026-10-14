import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

Widget accountSwitch({
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
