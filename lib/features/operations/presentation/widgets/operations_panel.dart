import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Cabecera compacta de paneles operativos (estilo login / Mi Cuenta).
class OperationsPanelHeader extends StatelessWidget {
  const OperationsPanelHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3D4550),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 12), trailing!],
    ],
  );
}

/// Contenedor plano con borde Platanitos (sin elevación Material).
class OperationsTile extends StatelessWidget {
  const OperationsTile({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  static const _radius = BorderRadius.all(Radius.circular(13));

  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: Material(
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: _radius,
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: _radius,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class OperationsAvatar extends StatelessWidget {
  const OperationsAvatar({
    super.key,
    required this.icon,
    this.warning = false,
    this.label,
  });

  final IconData icon;
  final bool warning;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final background = warning
        ? const Color(0xFFFFF0E0)
        : AppColors.softGreen;
    final foreground = warning ? const Color(0xFFC45C12) : AppColors.green;
    return CircleAvatar(
      backgroundColor: background,
      foregroundColor: foreground,
      child: label != null
          ? Text(
              label!,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            )
          : Icon(icon, color: foreground, size: 22),
    );
  }
}

class OperationsMetricCard extends StatelessWidget {
  const OperationsMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: OperationsTile(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          OperationsAvatar(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class OperationsEmptyTile extends StatelessWidget {
  const OperationsEmptyTile({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => OperationsTile(
    child: Text(
      message,
      style: const TextStyle(color: AppColors.muted),
    ),
  );
}

/// Padding horizontal estándar de paneles operativos.
EdgeInsets operationsListPadding(BuildContext context) =>
    const EdgeInsets.fromLTRB(16, 12, 16, 24);
