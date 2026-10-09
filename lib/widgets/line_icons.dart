import 'package:flutter/material.dart';

import '../core/app_theme.dart';

enum LineIcons { home, grid, bag, heart, user, back, bell }

/// Ícono de trazo fino dibujado sobre una grilla de 24×24.
/// Toma el color y el tamaño del [IconTheme] cuando no se indican.
class LineIcon extends StatelessWidget {
  const LineIcon(this.icon, {super.key, this.size, this.color});
  final LineIcons icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: dimension,
        child: CustomPaint(
          painter: _LineIconPainter(
            icon,
            color ?? theme.color ?? AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _LineIconPainter extends CustomPainter {
  const _LineIconPainter(this.icon, this.color);
  final LineIcons icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final path in _paths(icon)) {
      canvas.drawPath(path, paint);
    }
  }

  static List<Path> _paths(LineIcons icon) => switch (icon) {
    LineIcons.home => [
      Path()
        ..moveTo(3.5, 10.2)
        ..lineTo(12, 3.3)
        ..lineTo(20.5, 10.2)
        ..lineTo(20.5, 19)
        ..quadraticBezierTo(20.5, 20.7, 18.8, 20.7)
        ..lineTo(5.2, 20.7)
        ..quadraticBezierTo(3.5, 20.7, 3.5, 19)
        ..close(),
      Path()
        ..moveTo(9.6, 20.7)
        ..lineTo(9.6, 14.6)
        ..quadraticBezierTo(9.6, 13.6, 10.6, 13.6)
        ..lineTo(13.4, 13.6)
        ..quadraticBezierTo(14.4, 13.6, 14.4, 14.6)
        ..lineTo(14.4, 20.7),
    ],
    LineIcons.grid => [
      Path()..addRRect(
        RRect.fromLTRBR(3.5, 3.5, 20.5, 20.5, const Radius.circular(2.2)),
      ),
      Path()
        ..moveTo(3.5, 9.2)
        ..lineTo(20.5, 9.2)
        ..moveTo(3.5, 14.8)
        ..lineTo(20.5, 14.8)
        ..moveTo(9.2, 3.5)
        ..lineTo(9.2, 20.5)
        ..moveTo(14.8, 3.5)
        ..lineTo(14.8, 20.5),
    ],
    LineIcons.bag => [
      Path()
        ..moveTo(6.4, 3)
        ..lineTo(17.6, 3)
        ..lineTo(20.5, 6.8)
        ..lineTo(20.5, 19.2)
        ..quadraticBezierTo(20.5, 21, 18.7, 21)
        ..lineTo(5.3, 21)
        ..quadraticBezierTo(3.5, 21, 3.5, 19.2)
        ..lineTo(3.5, 6.8)
        ..close(),
      Path()
        ..moveTo(3.5, 6.8)
        ..lineTo(20.5, 6.8),
      Path()
        ..moveTo(15.6, 10.2)
        ..arcToPoint(
          const Offset(8.4, 10.2),
          radius: const Radius.circular(3.6),
        ),
    ],
    LineIcons.heart => [
      Path()
        ..moveTo(12, 20.4)
        ..lineTo(10.8, 19.3)
        ..cubicTo(6.1, 15.1, 3, 12.3, 3, 8.9)
        ..cubicTo(3, 6.1, 5.2, 4, 7.9, 4)
        ..cubicTo(9.5, 4, 11, 4.7, 12, 5.9)
        ..cubicTo(13, 4.7, 14.5, 4, 16.1, 4)
        ..cubicTo(18.8, 4, 21, 6.1, 21, 8.9)
        ..cubicTo(21, 12.3, 17.9, 15.1, 13.2, 19.3)
        ..close(),
    ],
    LineIcons.user => [
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(12, 7.6), radius: 3.9)),
      Path()
        ..moveTo(4.8, 20.6)
        ..lineTo(4.8, 19.2)
        ..arcToPoint(
          const Offset(8.6, 15.4),
          radius: const Radius.circular(3.8),
        )
        ..lineTo(15.4, 15.4)
        ..arcToPoint(
          const Offset(19.2, 19.2),
          radius: const Radius.circular(3.8),
        )
        ..lineTo(19.2, 20.6),
    ],
    LineIcons.back => [
      Path()
        ..moveTo(15, 18.5)
        ..lineTo(8.5, 12)
        ..lineTo(15, 5.5),
    ],
    LineIcons.bell => [
      Path()
        ..moveTo(4, 17)
        ..quadraticBezierTo(6.2, 15.4, 6.2, 11.8)
        ..lineTo(6.2, 9.3)
        ..arcToPoint(
          const Offset(17.8, 9.3),
          radius: const Radius.circular(5.8),
        )
        ..lineTo(17.8, 11.8)
        ..quadraticBezierTo(17.8, 15.4, 20, 17)
        ..close(),
      Path()
        ..moveTo(10.2, 20.2)
        ..quadraticBezierTo(12, 21.8, 13.8, 20.2),
    ],
  };

  @override
  bool shouldRepaint(_LineIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}
