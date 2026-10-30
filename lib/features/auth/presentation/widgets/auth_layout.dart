import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shop_widgets.dart';

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
