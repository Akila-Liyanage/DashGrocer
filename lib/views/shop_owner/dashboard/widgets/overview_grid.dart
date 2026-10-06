import 'package:flutter/material.dart';

import '../../../../core/theme/shop_owner_theme.dart';

/// The 2 x 2 summary grid: New Orders, Preparing, Ready Pickup, Products.
/// A null count means the data is still loading and shows as a dash.
class OverviewGrid extends StatelessWidget {
  const OverviewGrid({
    super.key,
    required this.newOrders,
    required this.preparing,
    required this.ready,
    required this.products,
    required this.onTapNewOrders,
    required this.onTapPreparing,
    required this.onTapReady,
    required this.onTapProducts,
  });

  final int? newOrders;
  final int? preparing;
  final int? ready;
  final int? products;
  final VoidCallback onTapNewOrders;
  final VoidCallback onTapPreparing;
  final VoidCallback onTapReady;
  final VoidCallback onTapProducts;

  @override
  Widget build(BuildContext context) {
    final hasNewOrders = (newOrders ?? 0) > 0;

    return Column(
      children: [
        EqualHeightRow(
          children: [
            Expanded(
              child: MetricCard(
                label: 'NEW ORDERS',
                value: newOrders?.toString(),
                valueColor: ShopColors.primary,
                onTap: onTapNewOrders,
                // Red dot: there are orders nobody has started yet.
                trailing: hasNewOrders
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ShopColors.error,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'PREPARING',
                value: preparing?.toString(),
                onTap: onTapPreparing,
                trailing: const Icon(
                  Icons.hourglass_top,
                  size: 16,
                  color: ShopColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        EqualHeightRow(
          children: [
            Expanded(
              child: MetricCard(
                label: 'READY PICKUP',
                value: ready?.toString(),
                valueColor: ShopColors.secondary,
                onTap: onTapReady,
                trailing: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: ShopColors.secondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'PRODUCTS',
                value: products?.toString(),
                onTap: onTapProducts,
                trailing: const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: ShopColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A row whose cards all take the height of the tallest one.
class EqualHeightRow extends StatelessWidget {
  const EqualHeightRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// White card with a small caption and one big number or amount.
/// Also used on the Sales Summary screen.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.valueColor = ShopColors.textPrimary,
    this.trailing,
  });

  final String label;

  /// Null shows a dash, meaning "still loading".
  final String? value;
  final VoidCallback? onTap;
  final Color valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
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
                    Expanded(
                      child: Text(
                        label,
                        style: ShopText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value ?? '–',
                    style: ShopText.metric.copyWith(color: valueColor),
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
