import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

enum SocialButtonType {
  facebook,
  google,
  guest,
  primary,
}

class SocialAuthButton extends StatefulWidget {
  final String text;
  final SocialButtonType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  const SocialAuthButton.facebook({
    super.key,
    this.text = 'Continue with Facebook',
    required this.onPressed,
    this.isLoading = false,
  }) : type = SocialButtonType.facebook;

  const SocialAuthButton.google({
    super.key,
    this.text = 'Continue with Google',
    required this.onPressed,
    this.isLoading = false,
  }) : type = SocialButtonType.google;

  const SocialAuthButton.guest({
    super.key,
    this.text = 'Continue as Guest',
    required this.onPressed,
    this.isLoading = false,
  }) : type = SocialButtonType.guest;

  const SocialAuthButton.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  }) : type = SocialButtonType.primary;

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.isLoading) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!widget.isLoading) {
      _scaleController.reverse();
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimaryOrGuest =
        widget.type == SocialButtonType.guest || widget.type == SocialButtonType.primary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: isPrimaryOrGuest ? const Color(0xFF00C265) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: isPrimaryOrGuest
                ? null
                : Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: isPrimaryOrGuest
                ? [
                    BoxShadow(
                      color: const Color(0xFF00C265).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimaryOrGuest ? Colors.white : AppColors.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.type == SocialButtonType.facebook) ...[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1877F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'f',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else if (widget.type == SocialButtonType.google) ...[
                        const _GoogleIconBadge(),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        widget.text,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: isPrimaryOrGuest ? FontWeight.w700 : FontWeight.w600,
                          color: isPrimaryOrGuest ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Stylized Google 'G' icon badge with official multicolor segments
class _GoogleIconBadge extends StatelessWidget {
  const _GoogleIconBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleGLogoPainter(),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);
    final paintBlue = Paint()..color = const Color(0xFF4285F4);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw Google 4-color arcs
    canvas.drawArc(rect, -0.785, 1.57, true, paintRed);
    canvas.drawArc(rect, 0.785, 1.57, true, paintYellow);
    canvas.drawArc(rect, 2.356, 1.57, true, paintGreen);
    canvas.drawArc(rect, 3.927, 0.785, true, paintBlue);

    // Cutout center
    final paintWhite = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, paintWhite);

    // Blue horizontal bar
    final barRect = Rect.fromLTRB(
      center.dx,
      center.dy - radius * 0.22,
      center.dx + radius,
      center.dy + radius * 0.22,
    );
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
