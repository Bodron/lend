import 'package:flutter/material.dart';

/// The floating black surface shared by the bottom navigation and app toasts.
class LendCurvedSurfacePainter extends CustomPainter {
  const LendCurvedSurfacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 24)
      ..quadraticBezierTo(0, 9, 20, 8)
      ..quadraticBezierTo(size.width / 2, -8, size.width - 20, 8)
      ..quadraticBezierTo(size.width, 9, size.width, 24)
      ..lineTo(size.width, size.height - 24)
      ..quadraticBezierTo(size.width, size.height, size.width - 24, size.height)
      ..lineTo(24, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 24)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.28), 12, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFF050505));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
