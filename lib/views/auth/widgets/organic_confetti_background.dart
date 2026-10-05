import 'package:flutter/material.dart';

/// Renders the soft mint/sage organic shapes scattered in the background
/// as seen in the reference Splash & Login screens.
class OrganicConfettiBackground extends StatelessWidget {
  final Widget child;

  const OrganicConfettiBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pure clean background
        Container(
          color: Colors.white,
        ),

        // Custom painter for the organic soft mint drops / confetti
        Positioned.fill(
          child: CustomPaint(
            painter: _OrganicConfettiPainter(),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}

class _OrganicConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA7F3D0).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final paintAccent = Paint()
      ..color = const Color(0xFF6EE7B7).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Top-left organic oval
    _drawPebble(canvas, Offset(size.width * 0.18, size.height * 0.12), 10, 18, -0.4, paint);

    // Top-right organic blob
    _drawPebble(canvas, Offset(size.width * 0.82, size.height * 0.16), 14, 22, 0.5, paintAccent);

    // Mid-left pebble
    _drawPebble(canvas, Offset(size.width * 0.14, size.height * 0.44), 8, 16, 0.25, paint);

    // Mid-right pebble
    _drawPebble(canvas, Offset(size.width * 0.88, size.height * 0.48), 12, 20, -0.6, paintAccent);

    // Lower-mid left drop
    _drawPebble(canvas, Offset(size.width * 0.20, size.height * 0.68), 14, 24, 0.35, paintAccent);

    // Bottom-right subtle accent
    _drawPebble(canvas, Offset(size.width * 0.84, size.height * 0.76), 10, 16, -0.2, paint);

    // Top subtle floating dot
    _drawPebble(canvas, Offset(size.width * 0.52, size.height * 0.08), 8, 12, 0.1, paint);
  }

  void _drawPebble(
    Canvas canvas,
    Offset center,
    double radiusX,
    double radiusY,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final rect = Rect.fromCenter(center: Offset.zero, width: radiusX * 2, height: radiusY * 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radiusX * 0.9));
    canvas.drawRRect(rrect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
