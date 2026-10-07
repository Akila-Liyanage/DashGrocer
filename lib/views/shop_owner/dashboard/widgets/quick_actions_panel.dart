import 'package:flutter/material.dart';

import '../../../../core/theme/shop_owner_theme.dart';

/// The shortcut cards under "ORDERS AND STOCKS": View Orders and Manage
/// Stock side by side, with the Sales Summary shortcut underneath.
class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({
    super.key,
    required this.newOrderCount,
    required this.salesTodayLabel,
    required this.onViewOrders,
    required this.onManageStock,
    required this.onOpenSales,
  });

  final int newOrderCount;

  /// For example "Today: Rs. 4,250 from 3 orders".
  final String salesTodayLabel;
  final VoidCallback onViewOrders;
  final VoidCallback onManageStock;
  final VoidCallback onOpenSales;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                iconColor: ShopColors.primary,
                label: 'View Orders',
                badge: newOrderCount > 0 ? '$newOrderCount new' : null,
                onTap: onViewOrders,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.edit_note,
                iconColor: ShopColors.textPrimary,
                label: 'Manage Stock',
                onTap: onManageStock,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SalesShortcut(label: salesTodayLabel, onTap: onOpenSales),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: ShopDecor.tile(color: ShopColors.surfaceMid),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final badgeText = badge;

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: ShopDecor.card(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconTile(icon: icon, color: iconColor),
                    const Spacer(),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ShopColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: ShopText.label.copyWith(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(label, style: ShopText.bodyStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SalesShortcut extends StatelessWidget {
  const _SalesShortcut({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShopDecor.card(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const _IconTile(
                  icon: Icons.bar_chart,
                  color: ShopColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales Summary', style: ShopText.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: ShopText.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: ShopColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
