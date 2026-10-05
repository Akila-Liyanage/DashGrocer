import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({
    super.key,
    required this.onFinish,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      imagePath: 'assets/images/onboarding1.jpg',
      fallbackNetworkUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1080&q=80',
      title: 'Buy Grocery',
      subtitle: 'Fresh groceries at your fingertips, shop with ease every day.',
    ),
    _OnboardingItem(
      imagePath: 'assets/images/onboarding2.jpg',
      fallbackNetworkUrl:
          'https://images.unsplash.com/photo-1506784365847-bbad939e9335?auto=format&fit=crop&w=1080&q=80',
      title: 'Easy Pickup',
      subtitle: 'Quickly prepared for pickup, fresh groceries in no time.',
    ),
    _OnboardingItem(
      imagePath: 'assets/images/onboarding3.jpg',
      fallbackNetworkUrl:
          'https://images.unsplash.com/photo-1498837167922-ddd27525d352?auto=format&fit=crop&w=1080&q=80',
      title: 'Enjoy Quality Food',
      subtitle: 'Enjoy Delicious Quality Food Every Time',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        itemCount: _items.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          final isLastPage = index == _items.length - 1;

          return Column(
            children: [
              // Top illustration / photo section
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: const Color(0xFFF9FAFB),
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          errorBuilder: (context, err, _) => Image.network(
                            item.fallbackNetworkUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    // Gradient overlay at bottom of image for seamless transition
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Card matching Figma
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 20,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        item.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF868889),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // If last page: Big "Get Start" button with dots underneath
                      if (isLastPage) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: AppColors.brandGreen.withValues(alpha: 0.3),
                            ),
                            onPressed: widget.onFinish,
                            child: Text(
                              'Get Start',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildDotsIndicator(),
                      ] else ...[
                        // Non-last pages: Skip on left, Dots in center, Next on right
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: widget.onFinish,
                              child: Text(
                                'Skip',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            _buildDotsIndicator(),
                            TextButton(
                              onPressed: _nextPage,
                              child: Text(
                                'Next',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brandGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _items.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentPage == i ? 18 : 6,
          decoration: BoxDecoration(
            color: _currentPage == i
                ? AppColors.brandGreen
                : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String imagePath;
  final String fallbackNetworkUrl;
  final String title;
  final String subtitle;

  const _OnboardingItem({
    required this.imagePath,
    required this.fallbackNetworkUrl,
    required this.title,
    required this.subtitle,
  });
}
