import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/shop_order.dart';
import '../widgets/button_spinner.dart';
import '../widgets/status_pill.dart';

/// The next step for an order, or null when nothing is left to do.
/// Used by the Order Queue cards and the Order Details screen so the wording
/// is the same everywhere.
String? nextActionLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.newOrder:
      return 'Start Preparing';
    case OrderStatus.preparing:
      return 'Mark Ready';
    case OrderStatus.ready:
      return 'Mark Completed';
    case OrderStatus.completed:
    case OrderStatus.cancelled:
      return null;
  }
}

/// One order in the Order Queue list.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.now,
    required this.busy,
    required this.onDetails,
    required this.onCall,
    required this.onAction,
  });

  final ShopOrder order;
  final DateTime now;

  /// True while this order's status change is being saved.
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onCall;

  /// Runs the next step (see [nextActionLabel]).
  final VoidCallback onAction;

  /// "Samba Rice 2 kg • Fresh Milk 1 L" for the first two items. Orders
  /// without an item list show their text summary instead.
  String get _itemSummary {
    if (!order.hasItemList) return order.itemsSummary ?? '';
    return order.items
        .take(2)
        .map((item) => '${item.name} ${item.quantityLabel}')
        .join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(order.status);
    final actionLabel = nextActionLabel(order.status);
    final moreItems = order.hasItemList ? order.itemCount - 2 : 0;
    final itemSummary = _itemSummary;

    return Container(
      decoration: ShopDecor.card(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order number, status and total.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '#${order.orderNumber}',
                                  style: ShopText.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusPill(status: order.status, compact: true),
                            ],
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: order.customerPhone.isEmpty ? null : onCall,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      order.customerName,
                                      style: ShopText.bodyStrong,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (order.customerPhone.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.call,
                                      size: 14,
                                      color: ShopColors.primary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatRs(order.total),
                          style: ShopText.title.copyWith(
                            color: ShopColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(order.itemCountLabel, style: ShopText.label),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PickupTile(order: order, now: now),
                if (itemSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: ShopDecor.tile(color: ShopColors.background),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            itemSummary,
                            style: ShopText.body.copyWith(
                              color: ShopColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (moreItems > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '+$moreItems more',
                            style: ShopText.label.copyWith(
                              color: ShopColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          style: ShopDecor.tonalButton(),
                          onPressed: onDetails,
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                          ),
                          label: const Text('Details'),
                        ),
                      ),
                    ),
                    if (actionLabel != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            style: ShopDecor.primaryButton(
                              color: order.status == OrderStatus.newOrder
                                  ? ShopColors.primaryButton
                                  : ShopColors.primary,
                            ),
                            onPressed: busy ? null : onAction,
                            child: busy
                                ? const ButtonSpinner()
                                : Text(
                                    actionLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Coloured bar down the left edge shows the status at a glance.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(
              color: colors.accent,
              child: const SizedBox(width: 6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pickup time with a short note about how soon it is.
class _PickupTile extends StatelessWidget {
  const _PickupTile({required this.order, required this.now});

  final ShopOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final countdown = pickupCountdown(order.pickupTime, now: now);

    var note = '';
    var urgent = false;
    switch (order.status) {
      case OrderStatus.newOrder:
      case OrderStatus.preparing:
        urgent = countdown.isUrgent;
        if (countdown.urgency == PickupUrgency.overdue) {
          note = 'Pickup time has passed';
        } else if (countdown.urgency == PickupUrgency.immediate) {
          note = 'Pickup due now';
        } else {
          note = 'Pickup ${countdown.label}';
        }
      case OrderStatus.ready:
        note = 'Packed, waiting for the customer';
      case OrderStatus.completed:
        note = 'Collected by the customer';
      case OrderStatus.cancelled:
        final reason = order.cancelReason;
        note = (reason == null || reason.isEmpty)
            ? 'Cancelled'
            : 'Cancelled: $reason';
    }

    final paidOnline = order.paymentMethod.toLowerCase().contains('online');

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShopDecor.tile(),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: urgent ? ShopColors.errorContainer : ShopColors.surfaceHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              urgent ? Icons.timer_outlined : Icons.schedule,
              size: 16,
              color: urgent ? ShopColors.error : ShopColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPickupSlot(order.pickupTime, now: now),
                  style: ShopText.bodyStrong,
                ),
                Text(
                  note,
                  style: ShopText.label.copyWith(
                    color: urgent ? ShopColors.error : ShopColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (paidOnline) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ShopColors.surfaceHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Paid Online',
                style: ShopText.label.copyWith(color: ShopColors.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
