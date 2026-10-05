import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/brand_logo_badge.dart';
import 'widgets/organic_confetti_background.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({
    super.key,
    required this.onFinish,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );

    _animController.forward();

    // Automatically transition to Welcome screen after 2.4 seconds
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        widget.onFinish();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFinish, // Allows instant skip on tap
      child: Scaffold(
        body: OrganicConfettiBackground(
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 40),

                  // Center Logo Badge with ambient glowing aura
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft Ambient Halo
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) => Container(
                              width: 170 * _glowAnimation.value,
                              height: 170 * _glowAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00C265).withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          const BrandLogoBadge(
                            circleSize: 104,
                            title: 'DashGrocer',
                            fontSize: 28,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Spinner matching the reference image
                  Padding(
                    padding: const EdgeInsets.only(bottom: 56),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00C265),
                            ),
                            backgroundColor: const Color(0xFF00C265).withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
