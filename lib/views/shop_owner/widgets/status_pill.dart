import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../models/shop_order.dart';

/// Colours for one order status. Each status has its own look so the stages
/// are easy to tell apart at a glance.
class StatusColors {
  const StatusColors(this.background, this.foreground, this.accent);

  /// Badge fill.
  final Color background;

  /// Badge text and dot.
  final Color foreground;

  /// Strong colour for the bar on the edge of an order card.
  final Color accent;

  static StatusColors of(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return const StatusColors(
          ShopColors.greenContainer,
          ShopColors.onGreenContainer,
          ShopColors.primary,
        );
      case OrderStatus.preparing:
        return const StatusColors(
          ShopColors.surfaceMid,
          ShopColors.secondary,
          ShopColors.secondary,
        );
      case OrderStatus.ready:
        return const StatusColors(
          ShopColors.primary,
          Colors.white,
          ShopColors.primaryButton,
        );
      case OrderStatus.completed:
        return const StatusColors(
          ShopColors.surfaceHigh,
          ShopColors.textSecondary,
          ShopColors.surfaceHighest,
        );
      case OrderStatus.cancelled:
        return const StatusColors(
          ShopColors.errorContainer,
          ShopColors.onErrorContainer,
          ShopColors.error,
        );
    }
  }
}

/// Status badge: a coloured dot followed by NEW, PREPARING, READY...
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final OrderStatus status;

  /// Smaller square-cornered version used next to the order number.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(compact ? 4 : 999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status.label.toUpperCase(),
            style: ShopText.label.copyWith(color: colors.foreground),
          ),
        ],
      ),
    );
  }
}
