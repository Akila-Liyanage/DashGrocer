import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';

/// Card for empty and error states: an icon, a title and a short message.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor = ShopColors.secondary,
    this.action,
  });

  /// Standard "could not load" card.
  const InfoCard.loadError({super.key, required String what})
    : icon = Icons.cloud_off_outlined,
      iconColor = ShopColors.error,
      title = 'Could not load $what',
      message =
          'Check your internet connection. If this Firebase project '
          'is new, create the Firestore database in the Firebase console.',
      action = null;

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShopDecor.card(),
      child: Column(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 8),
          Text(title, style: ShopText.subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(message, style: ShopText.body, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 4), action!],
        ],
      ),
    );
  }
}

/// Card with a spinner, shown while the first data is loading.
class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: ShopDecor.card(),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
