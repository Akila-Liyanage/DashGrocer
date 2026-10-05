import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

/// Modern Brand Logo Badge matching the circular emerald cart icon
/// with custom vector-drawn modern cart badge from the reference designs.
class BrandLogoBadge extends StatelessWidget {
  final double circleSize;
  final String title;
  final Color? titleColor;
  final double fontSize;
  final bool showTitle;

  const BrandLogoBadge({
    super.key,
    this.circleSize = 88.0,
    this.title = 'DashGrocer',
    this.titleColor,
    this.fontSize = 26.0,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emerald Green Circular Badge with rich gradient and soft shadow
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF10DF79),
                Color(0xFF00BA5E),
                Color(0xFF009E4E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C265).withValues(alpha: 0.38),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: circleSize * 0.58,
              height: circleSize * 0.58,
              child: CustomPaint(
                painter: _ModernCartLogoPainter(),
              ),
            ),
          ),
        ),

        if (showTitle) ...[
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: effectiveTitleColor,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the streamlined grocery cart logo with wheel dots
class _ModernCartLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Cart basket path with curved top handle
    final cartPath = Path();
    // Handle start
    cartPath.moveTo(w * 0.16, h * 0.22);
    cartPath.lineTo(w * 0.32, h * 0.22);
    // Down to basket base
    cartPath.lineTo(w * 0.40, h * 0.62);
    // Basket bottom
    cartPath.lineTo(w * 0.82, h * 0.62);
    // Basket right rim
    cartPath.lineTo(w * 0.90, h * 0.34);
    // Basket top rim back towards front
    cartPath.lineTo(w * 0.28, h * 0.34);

    canvas.drawPath(cartPath, strokePaint);

    // Two modern solid wheel dots
    final wheelRadius = w * 0.08;
    canvas.drawCircle(Offset(w * 0.46, h * 0.78), wheelRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.78), wheelRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
