import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Versatile image renderer supporting both bundled local assets ('assets/...')
/// and remote network URLs ('http...', 'https...') with unified error and loading handling.
class AppImageView extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl.trim();

    final fallback = errorWidget ??
        Center(
          child: Icon(
            Icons.shopping_basket_rounded,
            size: (width != null && height != null) ? (width! * 0.45).clamp(20.0, 56.0) : 32.0,
            color: AppColors.brandGreen.withValues(alpha: 0.65),
          ),
        );

    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandGreen.withValues(alpha: 0.5),
                  ),
                ),
              );
        },
      );
    }

    // Default fallback
    return fallback;
  }
}
